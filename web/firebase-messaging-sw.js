importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

// Your web app's Firebase configuration
firebase.initializeApp({
    apiKey: "AIzaSyD0eBxrnXLchWPOFPLq_YEEEYzgtVD6A2s",
    authDomain: "yemenchat-18235.firebaseapp.com",
    projectId: "yemenchat-18235",
    storageBucket: "yemenchat-18235.firebasestorage.app",
    messagingSenderId: "1020259285671",
    appId: "1:1020259285671:web:2b0b3f05b7a8df8c4fd8b8"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((message) => {
    console.log("Background message received:", message);

    const notificationTitle = message.notification?.title || "New Message";
    const notificationOptions = {
        body: message.notification?.body || "You have a new message",
        icon: "/icons/Icon-192.png"
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
