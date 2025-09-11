import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/experiment.dart';
import '../screens/settings_screen.dart';
import '../widgets/experiment_card.dart';
import '../widgets/support_banner.dart';
import '../screens/create_experiment_screen.dart';

enum SortOption {
  newest('新しい順'),
  deadline('締切が近い順'),
  reward('報酬が高い順'),
  duration('所要時間が短い順');

  final String label;
  const SortOption(this.label);
}

class HomeScreenBase extends StatefulWidget {
  final String title;
  final List<Experiment> experiments;
  final bool canCreateExperiment;
  final bool showOnlyAvailable;
  final bool isDemo;
  final VoidCallback? onNavigateToParticipations;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onCreateExperiment;
  final String? userName;
  final bool isWasedaUser;
  final String? currentUserId;

  const HomeScreenBase({
    super.key,
    required this.title,
    required this.experiments,
    this.canCreateExperiment = false,
    this.showOnlyAvailable = false,
    this.isDemo = false,
    this.onNavigateToParticipations,
    this.onSettingsTap,
    this.onCreateExperiment,
    this.userName,
    this.isWasedaUser = false,
    this.currentUserId,
  });

  @override
  State<HomeScreenBase> createState() => _HomeScreenBaseState();
}

class _HomeScreenBaseState extends State<HomeScreenBase> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  ExperimentType? _selectedType;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  SortOption _sortOption = SortOption.newest;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Experiment> get filteredExperiments {
    List<Experiment> filtered = widget.experiments;
    
    // 参加可能な実験のみ表示
    if (widget.showOnlyAvailable) {
      filtered = filtered.where((experiment) {
        // 終了・募集中以外の実験は除外
        if (experiment.status != ExperimentStatus.recruiting) {
          return false;
        }
        
        // 最大参加者数に達している実験は除外
        if (experiment.maxParticipants != null && 
            experiment.participants.length >= experiment.maxParticipants!) {
          return false;
        }
        
        return true;
      }).toList();
    }

    // 検索クエリでフィルタリング
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((experiment) {
        final query = _searchQuery.toLowerCase();
        return experiment.title.toLowerCase().contains(query) ||
            experiment.description.toLowerCase().contains(query) ||
            experiment.creatorId.toLowerCase().contains(query);
      }).toList();
    }

    // 種別でフィルタリング
    if (_selectedType != null) {
      filtered = filtered.where((experiment) => experiment.type == _selectedType).toList();
    }

    // 日付でフィルタリング
    if (_startDateFilter != null || _endDateFilter != null) {
      filtered = filtered.where((experiment) {
        // 実験期間を取得
        final experimentStart = experiment.recruitmentStartDate;
        final experimentEnd = experiment.recruitmentEndDate;
        if (experimentStart == null && experimentEnd == null) return true;
        
        // フィルター期間内に実験が存在するかチェック
        if (_startDateFilter != null && _endDateFilter != null) {
          // 期間指定の場合
          return (experimentEnd == null || experimentEnd.isAfter(_startDateFilter!.subtract(const Duration(days: 1)))) &&
                 (experimentStart == null || experimentStart.isBefore(_endDateFilter!.add(const Duration(days: 1))));
        } else if (_startDateFilter != null) {
          // 開始日のみ指定の場合
          return experimentEnd == null || experimentEnd.isAfter(_startDateFilter!.subtract(const Duration(days: 1)));
        } else if (_endDateFilter != null) {
          // 終了日のみ指定の場合
          return experimentStart == null || experimentStart.isBefore(_endDateFilter!.add(const Duration(days: 1)));
        }
        return true;
      }).toList();
    }

    // ソート
    switch (_sortOption) {
      case SortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.deadline:
        filtered.sort((a, b) {
          if (a.recruitmentEndDate == null) return 1;
          if (b.recruitmentEndDate == null) return -1;
          return a.recruitmentEndDate!.compareTo(b.recruitmentEndDate!);
        });
        break;
      case SortOption.reward:
        filtered.sort((a, b) => b.reward.compareTo(a.reward));
        break;
      case SortOption.duration:
        filtered.sort((a, b) {
          if (a.duration == null) return 1;
          if (b.duration == null) return -1;
          return a.duration!.compareTo(b.duration!);
        });
        break;
    }

    return filtered;
  }

  Widget _buildTypeFilterChip(ExperimentType? type, String label) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF8E1728),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getDateFilterText() {
    if (_startDateFilter == null && _endDateFilter == null) {
      return 'すべての期間';
    }
    
    final dateFormat = (_startDateFilter?.month == _endDateFilter?.month)
        ? 'M/d'
        : 'M/d';
    
    if (_startDateFilter != null && _endDateFilter != null) {
      if (_startDateFilter == _endDateFilter) {
        return '${_startDateFilter!.month}/${_startDateFilter!.day}';
      }
      return '${_startDateFilter!.month}/${_startDateFilter!.day} - ${_endDateFilter!.month}/${_endDateFilter!.day}';
    } else if (_startDateFilter != null) {
      return '${_startDateFilter!.month}/${_startDateFilter!.day}以降';
    } else {
      return '${_endDateFilter!.month}/${_endDateFilter!.day}まで';
    }
  }

  Widget _buildDateFilterButton(String label, String buttonType) {
    final isActive = _isDateButtonActive(buttonType);
    
    return Material(
      color: isActive ? const Color(0xFF8E1728) : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _handleDateFilter(buttonType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _handleDateFilter(String buttonType) {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final in3days = today.add(const Duration(days: 3));
      final weekday = now.weekday;
      final weekStart = today.subtract(Duration(days: weekday - 1));
      final weekEnd = today.add(Duration(days: 7 - weekday));
      
      switch (buttonType) {
        case 'reset':
          _startDateFilter = null;
          _endDateFilter = null;
          break;
        case 'today':
          _startDateFilter = today;
          _endDateFilter = today;
          break;
        case 'tomorrow':
          _startDateFilter = tomorrow;
          _endDateFilter = tomorrow;
          break;
        case 'in3days':
          _startDateFilter = today;
          _endDateFilter = in3days;
          break;
        case 'thisWeek':
          _startDateFilter = weekStart;
          _endDateFilter = weekEnd;
          break;
      }
    });
  }

  bool _isDateButtonActive(String buttonType) {
    if (_startDateFilter == null && _endDateFilter == null) {
      return buttonType == 'reset';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final in3days = today.add(const Duration(days: 3));
    
    switch (buttonType) {
      case 'reset':
        return false;
      case 'today':
        return _startDateFilter == today && _endDateFilter == today;
      case 'tomorrow':
        return _startDateFilter == tomorrow && _endDateFilter == tomorrow;
      case 'in3days':
        return _startDateFilter == today && _endDateFilter == in3days;
      case 'thisWeek':
        final weekday = now.weekday;
        final weekStart = today.subtract(Duration(days: weekday - 1));
        final weekEnd = today.add(Duration(days: 7 - weekday));
        return _startDateFilter == weekStart && _endDateFilter == weekEnd;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final safeAreaTop = mediaQuery.padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // 支援バナー
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SupportBanner(),
          ),
          // CustomScrollViewでスムーズなスクロールを実現
          Padding(
            padding: const EdgeInsets.only(top: 30), // バナーの高さ分
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // SliverAppBarで自動的に隠れるヘッダー
                SliverAppBar(
                  floating: false,
                  pinned: false,
                  snap: false,
                  expandedHeight: isSmallScreen ? 250.0 : 230.0,
                  toolbarHeight: 70.0,
                  backgroundColor: Colors.white,
                  elevation: 1,
                  titleSpacing: 0,
                  centerTitle: false,
                  leading: IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.science,
                        size: 24,
                        color: Color(0xFF8E1728),
                      ),
                    ),
                    onPressed: () {},
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  actions: [
                    if (widget.userName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: Row(
                            children: [
                              if (widget.isWasedaUser)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '早稲田',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (widget.isWasedaUser) const SizedBox(width: 4),
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                widget.userName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (!widget.isDemo)
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: widget.onSettingsTap ?? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      children: [
                        const SizedBox(height: 70), // AppBar部分のスペース
                        // フィルター部分
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              // 検索バー
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '実験を検索...',
                                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 日付フィルターボタン
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildDateFilterButton('すべて', 'reset'),
                                    const SizedBox(width: 4),
                                    _buildDateFilterButton('今日', 'today'),
                                    const SizedBox(width: 4),
                                    _buildDateFilterButton('明日', 'tomorrow'),
                                    const SizedBox(width: 4),
                                    _buildDateFilterButton('3日以内', 'in3days'),
                                    const SizedBox(width: 4),
                                    _buildDateFilterButton('今週', 'thisWeek'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 種別切り替えボタン
                              SizedBox(
                                height: 32,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildTypeFilterChip(null, 'すべて'),
                                    const SizedBox(width: 8),
                                    ...ExperimentType.values.map((type) => 
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: _buildTypeFilterChip(type, type.label),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // ソート選択とフィルタ情報
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (_startDateFilter != null || _endDateFilter != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8E1728)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _getDateFilterText(),
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E1728)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<SortOption>(
                                        value: _sortOption,
                                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                                        iconSize: 20,
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        onChanged: (SortOption? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _sortOption = newValue;
                                            });
                                          }
                                        },
                                        items: SortOption.values.map<DropdownMenuItem<SortOption>>((SortOption value) {
                                          return DropdownMenuItem<SortOption>(
                                            value: value,
                                            child: Text(value.label, style: const TextStyle(fontSize: 11)),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 実験カードのグリッド
                if (filteredExperiments.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? '「$_searchQuery」に一致する実験が見つかりません'
                                : '実験がありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 600,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        mainAxisExtent: 230,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final experiment = filteredExperiments[index];
                          return RepaintBoundary(
                            child: ExperimentCard(
                              experiment: experiment,
                              isDemo: widget.isDemo,
                              currentUserId: widget.currentUserId,
                            ),
                          );
                        },
                        childCount: filteredExperiments.length,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.canCreateExperiment
          ? FloatingActionButton.extended(
              heroTag: "create_experiment_fab",
              onPressed: widget.onCreateExperiment ?? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateExperimentScreen()),
                );
              },
              backgroundColor: const Color(0xFF8E1728),
              label: const Text('実験を作成'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}