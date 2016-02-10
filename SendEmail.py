import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email import Encoders
import os

def sendEmail(to, subject, text, attach):
   msg = MIMEMultipart()
   
   msg['From'] = sender
   msg['To'] = ', '.join(to)
   msg['Subject'] = subject

   msg.attach(MIMEText(text))

   '''
   this is for attachements if needed
   
   part = MIMEBase('application', 'octet-stream')
   part.set_payload(open(attach, 'rb').read())
   Encoders.encode_base64(part)
   part.add_header('Content-Disposition',
           'attachment; filename="%s"' % os.path.basename(attach))
   msg.attach(part)
   '''

   mailServer = smtplib.SMTP("smtp.gmail.com", 587)
   mailServer.ehlo()
   mailServer.starttls()
   mailServer.ehlo()
   mailServer.login(sender, sender_pwd)
   mailServer.sendmail(sender, to, msg.as_string())
   mailServer.close()


sender = "address@email.com"
sender_pwd = "password"
receivers = ["address@email.com"]   # verizon texts by emailing phone number
                                                                  # "number@vtext.com"
                                                                  
sendEmail(receivers, "Test Subject","Test message.","")
