require 'sinatra'
require 'open-uri'
require 'json'

class App < Sinatra::Base
  get '/' do
    erb :form
  end

  post '/results' do
    scrape_reddit
    erb :results
  end

  #
  # Main scraper method that takes the user
  # input from the form and scrapes reddit.com
  #
  # @return [Array] images - An array of hashes that contain info about each image
  #
  def scrape_reddit
    sub   = params[:subreddit]
    score = params[:score].to_i
    count = params[:submissions].to_i

    url = "http://reddit.com/r/#{sub}/.json?limit=#{count}"
    reddit = open(url).read
    reddit_json = JSON.parse(reddit)

    images = []

    count.times do |n|
      img = {
        title: reddit_json['data']['children'][n]['data']['title'],
        url:   reddit_json['data']['children'][n]['data']['url'],
        score: reddit_json['data']['children'][n]['data']['score']
      }

      if valid_img?(img) && img[:score] >= score
        img[:url] << '.gif'
        images << img
      end
    end

    images
  end

  #
  # Checks to see if the image url is an
  # imgur link and that it is not an album or gallery
  #
  # @param [String] img - The URL received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def valid_img?(img)
    imgur?(img) && !album?(img) && !img[:url].end_with?('.gifv')
  end

  #
  # Checks to see if the image url is an imgur link
  #
  # @param [String] img  - The URL received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def imgur?(img)
    img[:url][7..11] == 'imgur' ||
    img[:url][7..11] == 'i.img' ||
    img[:url][7..11] == 'm.img'
  end

  #
  # Checks to see if the image url
  # is an album or a gallery
  #
  # @param [String] img - The
  # @return [Boolean]
  #
  def album?(img)
    img[:url][16..18] == '/a/' || img[:url][16..18] == '/ga'
  end
end
