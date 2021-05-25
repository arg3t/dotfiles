{
  "host": "outlook.office365.com",
  "port": 993,
  "tls": true,
  "tlsOptions": {
    "rejectUnauthorized": true
  },
  "username": "yigitcolakoglu@hotmail.com",
  "passwordCmd": "pass show AppPass/microsoft.com/yigitcolakoglu@hotmail.com",
  "onNewMail": "mailsync yigitcolakoglu@hotmail.com",
  "boxes": [
    "INBOX"
  ]
}
