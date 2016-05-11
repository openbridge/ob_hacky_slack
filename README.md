# Hacky Slack

Hacky Slack is a shell script that will post messages to a Slack webhook API endpoint.


From Slack:

<i>Incoming Webhooks are a simple way to post messages from external sources into Slack. They make use of normal HTTP requests with a JSON payload, which includes the message and a few other optional details described later. Message Attachments (https://api.slack.com/docs/attachments) can also be used in Incoming Webhooks to display richly-formatted messages that stand out from regular chat messages.</i>


Why is it called Hacky Slack? First, this reflects my "hacking" something together that accomplished my goals. Second, I played a ton of Hacky Sack (https://en.wikipedia.org/wiki/Hacky_Sack) when I was a teenager.

# Overview
There are two goal of Hacky Slack. The first was to was to create a generic shell client for the Slack messaging API. The second was to take advantage of the Slack messaging interface to allow applications, like Monit, to style its events. In support of both goals Hacky Slack offers customizations for external applications, like Monit, via external config files (See the Monit example).

Also, in support of having more compelling Slack messages, a small collection of icons were created. The icons are meant to provide visual cues to the user so they can more easily identify the context of a message they received in Slack.


# Requirements

First, you need to get yourself a Slack account. Go to the Slack webite: https://slack.com/

Second, you need create an incoming webhook. Go here to learn how: https://api.slack.com/incoming-webhooks

As a result going through those two steps, you should get the following:

## Slack API Tokens

 You need to make sure that your Slack token is set as a system variable <code>${SLACK_TOKEN}</code> or you can pass it to Hacky Slack via <code> -k "whatever-you-get-from-slack"</code>. You can also hard code it into <code>slack.sh</code> as <code>TOKEN="whatever-you-get-from-slack"</code>

## Slack API Webhook Endpoint

 Hacky Slack will default to the Slack API endpoint URL <code>https://hooks.slack.com/services/</code>. However, if you want to use a different one simply pass it via <code> -w "https://whatever.slack.com/provides/"</code>

## Environment
Hacky Slack should run in most modern Linux environments. It has been tested in a CentOS 7 Docker container and Mac OS X. However, you will need to make sure a few things are setup in your environment:

#### cURL

Hacky Slack requires cURL (https://curl.haxx.se). Most systems have it installed. However, if you are running Hacky Slack in Docker cURL may not be installed.

# Installation

## slack.sh

Installation is pretty simple. Just copy the <code>slack.sh</code> to <code>/usr/local/bin</code>. Then <code>chmod +x /usr/local/bin/slack.sh</code>.

Please note that the default config (slack.sh) assumes you are installing slack into <code>/usr/local/bin</code>:

```
APP="/usr/local/bin/slack.sh"
BIN="/usr/bin/slack"
```

BIN is used to <code>ln</code> to APP to BIN. This will allow you to use <code>slack</code> vs <code>/usr/local/bin/slack.sh</code>

If you decide to copy Hacky Slack to a different APP directory change the settings accordingly.

# Using Hacky Slack

Hacky Slack allowed you to pass a variety attributes as defined by the Slack messaging specs:

```
-a, Attachment      Sends a messages as an attachment."
-A, Author          Display the author's name."
-b, Author Link     A URL that will hyperlink the author_name text mentioned above. (Author name is required)."
-B, Author Icon     A URL that displays a small image to the left of the author_name text.(Author name is required)."
-c, Channel         The location the messages should be delivered. Use # or @ to prefix (#general or @joe)"
-C, Color           This value is used to color the border along the left side of the message attachment."
-h, Help            Show the command options for Slack."
-i, Icon            A URL to an image file that will be displayed inside a message attachment."
-I, Image           Small text used to display the author's name."
-m, Mode            Mode toggles application specific behaviors (e.g., preconfigured Monit settings)."
-N, Thumbnail       A URL to an image file that will be displayed as a thumbnail on the right side of a message attachment."
-p, Pretext         This is optional text that appears above the message attachment block."
-s, Status          An optional value that can either be one of ok, info, warn or error."
-t, Text            This is the main text in a message attachment, and can contain standard message markup."
-T, Title           The title is displayed as larger, bold text near the top of a message attachment."
-L, Title Link      A valid URL in the will ensure the title text will be hyperlinked."
-k, Token           Authenticates the POST to Slack."
-u, Username        User that posts the message."
-w, Webhook         The Slack API service endpoint to POST messages. Defaults to 'https://hooks.slack.com/services/'"
```
For more information on the above parameters, please check out the Slack docs:
* https://api.slack.com/docs/formatting
* https://api.slack.com/docs/attachments


# Send A Message
The channel is "general" with username "hacky-slack". The icon is "apple" and the author is "apple". The author name is linked to "apple.com" and the text sent in the message is "Where are the new 2016 Macbook models?"

```
slack -c "#general" -u "hacky-slack" -i "apple" -a "Macbook" -b "http://www.apple.com/ -t "Where are the new 2016 Macbook models?"
```

Here is a sample message and a screenshot of the message with various flags set.

```
slack -a -t "Hello World" -i ":slack:" -T "Titles are awesome" -p "Pretext is so helpful to include" -s "info"
```

Here is the command represented in Slack:

![Generic Message Examples](icons/png/generic-message.png?raw=true "Generic INFO")


Note: These examples assume you have set your token and webhook endpoint.


# Hacky Slack + Monit

Monit is a system monitoring and recovery tool. More on Monit here: https://mmonit.com/monit/

Hacky Slack was initially conceived to provide better support for Monit within Slack, especially customizing the Slack message UI to reflect smarter Monit events. Also, using Monit event variables in a Slack message allowed Hacky Slack the ability to trigger messages with minimal user input. This also means greater consistency for Monit messages as it ensures a common messaging approach across teams and systems.


#### Monit Hack Slack Example Message
Here is an example error message from Monit:

![Monit Examples](icons/png/monit-message.png?raw=true "Monit OK")

Notice the icon and matching message color highlight. Also, the content of each message, when triggered by Monit, is automatically populated.

This is accomplished by using Monit variables to populate specific parts of the Slack message:

```
USERNAME="monit @ ${IP}"
TITLE="${MONIT_SERVICE}"
TEXT="${MONIT_DESCRIPTION}"
PRETEXT="${MONIT_DATE} | ${MONIT_HOST}: ${MONIT_EVENT}"
FALLBACK="${MONIT_DATE} | ${MONIT_HOST}: ${MONIT_EVENT}"
```


#### Example Monit Status Icons
The message will visually change based on the use of the status flag <code>-s</code>. Based on the <code>-s</code> passed to Hacky Slack, one of 4 treatments will be applied to the message:

|  Icon |  Name |
|---|---|
| ![Monit Ok](icons/png/monit-ok.png?raw=true "Monit OK") | Monit OK <code>-s "ok"</code> |
| ![Monit info](icons/png/monit-info.png?raw=true "Monit INFO") | Monit INFO  <code>-s "info"</code> |
| ![Monit Warn](icons/png/monit-warn.png?raw=true "Monit WARN") | Monit WARN <code>-s "warn"</code> |
| ![Monit Error](icons/png/monit-error.png?raw=true "Monit ERROR") | Monit ERROR <code>-s "error"</code> |

In a future release, the look and feel can be tailored to the specific Monit event. For example, if there is a network event, then Hack Slack would customize the message to reflect that event type by using a specific set of icons and colors. At the moment, the 4 events above are the only customizations that are active.


## Using Hacky Slack in Your Monit Configs

Below is a Monit statement triggers an alert if the memory exceeds 15MB for 2 cycles. It will repeat the alert every 3 cycles. Once the condition that triggered the alert returns to normal, Monit will issue an all clear message to Slack.

```
if memory > 15 MB for 2 cycles then exec /usr/bin/bash -c "sh /usr/local/bin/slack.sh -a -c #testing -s error -M monit >> /ebs/logs/foo.log 2<&1" repeat every 3 cycles else if succeeded then exec /usr/bin/bash -c "sh /usr/local/bin/slack.sh -a -c #testing -s ok -M monit >> /ebs/logs/foo.log 2<&1"
```
The <code>-a</code> flag sets the attachment flag. This is the expanded message format seen above. The <code>-c</code> flag sets the channel to deliver the message to. In this case the channel is "#testing". The <code>-s</code> flag sets the status the message should inherit. The example above uses "error" and
ok". Lastly, the <code>-M</code> flag is set to "monit". This tells Hacky Slack to use the Monit config.

Here is an example for monitoring crond:
```
check process crond with pidfile "/var/run/crond.pid"
      start program = "/etc/init.d/crond start" with timeout 60 seconds
      stop program = "/etc/init.d/crond stop"
      if 2 restarts within 3 cycles then exec /usr/bin/bash -c "sh /usr/local/bin/slack.sh -a -c #testing -s error -M monit" repeat every 3 cycles else if succeeded then exec /usr/bin/bash -c "sh /usr/local/bin/slack.sh -a -c #testing -s ok -M monit"
      if 5 restarts within 5 cycles then timeout
```
### Using Hacky Slack in with other apps.

Hacky Slack can be extended to support other applications besides Monit. For example, Nagios monitoring or Cron. Really, any application can send messages via Hacky Slack.


Since no user (<code>- u</code>) was specified it will default to using the host system IP address

# Icons

Included are various Slack themed icons (<code?/icons/png</code>). The icons are sized at (128x128) to meet Slack requirements. To use these icons they need to be added via the Slack application UI and referenced in the command line flag <code>-i</code>. More icons will be added over time.

#### AWS

|  Icon |  Name |
|---|---|
| ![bug Ok](icons/png/aws-cache.png?raw=true "bug OK") | AWS ElastiCache |
| ![bug info](icons/png/aws-rds.png?raw=true "bug INFO") | AWS RDS |
| ![bug Warn](icons/png/aws-redshift.png?raw=true "bug WARN") | AWS Redshift |


#### BUG

|  Icon |  Name |
|---|---|
| ![bug Ok](icons/png/bug-ok.png?raw=true "bug OK") | bug OK |
| ![bug info](icons/png/bug-info.png?raw=true "bug INFO") | bug INFO |
| ![bug Warn](icons/png/bug-warn.png?raw=true "bug WARN") | bug WARN |
| ![bug Error](icons/png/bug-error.gif?raw=true "bug ERROR") | bug ERROR |

#### CODE

|  Icon |  Name |
|---|---|
| ![bug Ok](icons/png/code.png?raw=true "bug OK") | Code |

#### CPU

|  Icon |  Name |
|---|---|
| ![cpu Ok](icons/png/cpu-ok.png?raw=true "Monit OK") | CPU OK |
| ![cpu info](icons/png/cpu-info.png?raw=true "Monit INFO") | CPU INFO |
| ![cpu Warn](icons/png/cpu-warn.png?raw=true "Monit WARN") | CPU WARN |
| ![cpu Error](icons/png/cpu-error.png?raw=true "Monit ERROR") | CPI ERROR |

#### CRON

|  Icon |  Name |
|---|---|
| ![Cron Ok](icons/png/cron-ok.png?raw=true "Cron OK") | Cron OK |
| ![Cron Ok](icons/png/cron-warn.png?raw=true "Cron WARN") | Cron WARN |
| ![Cron Ok](icons/png/cron-error.png?raw=true "Cron ERROR") | Cron ERROR |

#### DISK

|  Icon |  Name |
|---|---|
| ![bug Ok](icons/png/disk.png?raw=true "bug OK") | Disk |

#### MEMORY

|  Icon |  Name |
|---|---|
| ![mem Ok](icons/png/mem-ok.png?raw=true "mem OK") | MEM OK |
| ![mem info](icons/png/mem-info.png?raw=true "mem INFO") | MEM INFO |
| ![mem Warn](icons/png/mem-warn.png?raw=true "mem WARN") | MEM WARN |
| ![mem Error](icons/png/mem-error.png?raw=true "mem ERROR") | MEM ERROR |

#### MISC

|  Icon |  Name |
|---|---|
| ![Database Check](icons/png/database-check.png?raw=true "Database Check") | Database Check |
| ![Integration](icons/png/integration.png?raw=true "mem INFO") | Integration |
| ![Stop](icons/png/stop.png?raw=true "Stop") | Stop |
| ![Stop 2](icons/png/stop2.png?raw=true "mem ERROR") | Stop 2 |



# Reference

Hacky Slack was inspired by the following resources:
* https://www.jverdeyen.be/devops/monit-slack-notifications/
* https://github.com/course-hero/slacktee
* https://github.com/rockymadden/slack-cli
* https://api.slack.com/community
* https://mmonit.com/wiki/MMonit/SlackNotification
* Icons courtesy of http://iconmonstr.com and AWS


# License

The MIT License (MIT)
Copyright (c) <year> <copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
