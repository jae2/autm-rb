FROM ruby:alpine

ADD . /jaetech
WORKDIR /jaetech
RUN apk update
RUN apk add alpine-sdk
RUN apk add libxml2 ruby-dev libxml2-dev libxslt-dev
RUN apk add nodejs python
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install
RUN apk del alpine-sdk ruby-dev libxml2 libxml2-dev libxslt-dev
CMD ["bundle","exec","jekyll", "serve"]
