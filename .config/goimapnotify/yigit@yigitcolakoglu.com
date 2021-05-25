{
  "host": "mail.privateemail.com",
  "port": 993,
  "tls": true,
  "tlsOptions": {
    "rejectUnauthorized": true
  },
  "username": "yigit@yigitcolakoglu.com",
  "passwordCmd": "pass show Email/privateemail.com/yigit@yigitcolakoglu.com",
  "onNewMail": "mailsync yigit@yigitcolakoglu.com",
  "boxes": [
    "INBOX"
  ]
}
