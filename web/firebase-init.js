// Firebase SDK initialization script
// This ensures Firebase is properly initialized before Flutter starts

window.addEventListener('load', function() {
  // Firebase configuration
  const firebaseConfig = {
    apiKey: "AIzaSyClIA2_3fHJuHoOKY5AVG1OXdpIyJTkqy0",
    authDomain: "waselab-30308.firebaseapp.com",
    projectId: "waselab-30308",
    storageBucket: "waselab-30308.firebasestorage.app",
    messagingSenderId: "788143974236",
    appId: "1:788143974236:web:YOUR-WEB-APP-ID"
  };

  // Initialize Firebase only if not already initialized
  if (typeof firebase !== 'undefined' && !firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
  }
});