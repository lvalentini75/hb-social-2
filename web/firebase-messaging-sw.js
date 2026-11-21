importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDleo3wSVDPAKhNBfiv7BpwXaHmV-cTi5s',
  appId: '1:261012257359:web:45298dd16dc2d81179483a',
  messagingSenderId: '261012257359',
  projectId: 'hb-social-5d72a',
  authDomain: 'hb-social-5d72a.firebaseapp.com',
  storageBucket: 'hb-social-5d72a.firebasestorage.app'
});

firebase.messaging();