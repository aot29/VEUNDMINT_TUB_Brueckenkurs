//config file for watchdog
module.exports = {
  services: [
    {name: 'feedback', url: 'http://localhost/mint/converter/server/feedback.php'},
    {name: 'userdata', url: 'http://localhost/mint/converter/server/userdata.php'},
    {name: 'course', url: 'http://localhost/mint/testhtml'}
  ],
  //timeout in seconds
  timeout: 10,
  //watchdog interval in minutes
  interval: 5
};
