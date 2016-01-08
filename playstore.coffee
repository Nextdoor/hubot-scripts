# Description:
#   All things Google's Playstore
#
#   Set your Google Playstore application id as an
#   environment variable `PLAYSTORE_APP_ID`
#   e.g. PLAYSTORE_APP_ID=com.nextdoor
#
# Dependencies:
#   cheerio
#
# Commands:
#   hubot playstore version - What is the latest version?
#   hubot playstore rating - What is the rating version?
#   hubot playstore specs - Show all specs about the current Android App.
#
# Authors:
#   Abhijeet Kumar (abhijeet@nextdoor.com)
#   Jeff Robidoux (jeff@nextdoor.com)
#   Daisuke Fujiwara (daisuke@nextdoor.com

cheerio = require('cheerio')

getValue = (body, selector) ->
  $ = cheerio.load(body)
  $(selector).text().trim()

getPlaystoreURL = () ->
  env_var = process.env.PLAYSTORE_APP_ID
  appID = if env_var then env_var.toString() else ""
  return "https://play.google.com/store/apps/details?id=#{appID}"


currentPlayStoreVersion = null
checkPlayStoreVersion = (robot) ->
    robot.http(getPlaystoreURL())
      .get() (err, res, body) ->
        playstoreVersion = getValue body, 'div[itemprop=softwareVersion]'

        if not currentPlayStoreVersion
          currentPlayStoreVersion = playstoreVersion
          return

        if currentPlayStoreVersion == playstoreVersion
          return

        updatedDate = getValue body, 'div[itemprop=datePublished]'
        currentPlayStoreVersion = playstoreVersion
        message = "<!everyone>, new version of the Android app, v#{currentPlayStoreVersion}, is now available for download (updated #{updatedDate})"
        robot.messageRoom "mobile", message

module.exports = (robot) ->
  checkPlayStoreVersion(robot)

  robot.respond /(.*) playstore version/i, (msg) ->
    msg.http(getPlaystoreURL())
       .get() (err, res, body) ->
         msg.send "Current live version of Android is v#{getValue body, 'div[itemprop=softwareVersion]'} in Google Playstore."

  robot.respond /(.*) playstore rating/i, (msg) ->
    msg.http(getPlaystoreURL())
       .get() (err, res, body) ->
         msg.send "Nextdoor Android has a score of #{getValue body, '.score'}/5 with #{getValue body, '.reviews-num'} total reviews."

  robot.respond /(.*) playstore specs/i, (msg) ->
     msg.http(getPlaystoreURL())
       .get() (err, res, body) ->
        version = getValue body, 'div[itemprop=softwareVersion]'
        datePublished = getValue body, 'div[itemprop=datePublished]'
        score = getValue body, '.score'
        numReviews = getValue body, '.reviews-num'
        numDownloads = getValue body, 'div[itemprop=numDownloads]'
        minOS = getValue body, 'div[itemprop=operatingSystems]'
        fileSize = getValue body, 'div[itemprop=fileSize]'
        robot.emit 'slack-attachment', {
            'message': msg.message,
            'content': {
                "color": "#1E9E5E",
                "mrkdwn": "true",
                "mrkdwn_in": ["text"],
                "text": "*Version:* #{version}\n"+
                        "*Date Published:* #{datePublished}\n"+
                        "*Rating:* #{score}/5\n"+
                        "*Number of reviews:* #{numReviews}\n"+
                        "*Installs:* #{numDownloads}\n"+
                        "*Min Android Version:* #{minOS}\n"+
                        "*File Size:* #{fileSize}"}
        }

  robot.on "playstore:new_version_notification", (data) ->
    checkPlayStoreVersion(robot)
