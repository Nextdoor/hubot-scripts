# Description:
#   Creates a Librato Annotation whenever a word #librato is presented
#   The annotation marker is "notice-<room>" with title of author's email
#   and the body being the entire content of the message
#
# Dependencies:
#   None
#
# Commands:
#   Any phrase that includes #librato will be annotated.
#
# Author:
#   Mikhail Simin (mikhail@nextdoor.com)

module.exports = (robot) ->

  robot.hear /(.*)#librato(.*)/i, (orig) ->

    email = process.env.LIBRATO_EMAIL
    token = process.env.LIBRATO_TOKEN

    # Can only really trust the email since everything else is easily changable
    user_email = orig.message.user.email_address
    room = orig.message.room
    auth = 'Basic ' + new Buffer(email + ':' + token).toString('base64')

    data = JSON.stringify({
        title: user_email,
        description: orig.message.text
    })

    console.log("Sending Librato annotation from #{user_email}.")
    orig.http('https://metrics-api.librato.com/v1/annotations/notice-' + room)
      .headers(Authorization: auth, 'Content-Type': 'application/json',)
      .post(data) (err, res, body) ->
        if err
          orig.reply "Encountered an error :( #{err}"
          return

        body = JSON.parse(body)
        if body.errors
          orig.reply "Encountered an error: #{body.errors.request[0]}"
          return

        orig.send "Saved."
