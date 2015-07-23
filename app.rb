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

  # Main scraper method that takes the user
  # input from the form and scrapes a subreddit
  # from reddit.com
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
        title:    reddit_json['data']['children'][n]['data']['title'],
        img_url:  reddit_json['data']['children'][n]['data']['url'],
        post_url: reddit_json['data']['children'][n]['data']['permalink'],
        score:    reddit_json['data']['children'][n]['data']['score']
      }

      if valid_img?(img) && img[:score] >= score
        img[:img_url] << '.gif'
        images << img
      end
    end

    images
  end

  # Checks to see if the image url is an
  # imgur link and that it is only a single image
  #
  # @param [Hash] img - The image details received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def valid_img?(img)
    imgur?(img) &&
    !album?(img) &&
    !gallery?(img) &&
    !gifv?(img) &&
    !multiple_imgs?(img)
  end

  # Checks to see if the image url is an imgur link
  #
  # @param [Hash] img  - The image details received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def imgur?(img)
    img[:img_url][7..11] == 'imgur' ||
    img[:img_url][7..11] == 'i.img' ||
    img[:img_url][7..11] == 'm.img'
  end

  # Checks to see if the image url is an album
  #
  # @param [Hash] img - The image details received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def album?(img)
    img[:img_url][16..18] == '/a/' ||
    img[:img_url][18..20] == '/a/'
  end

  # Checks to see if the image url is a gallery
  #
  # @param [Hash] img - The image details received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def gallery?(img)
    img[:img_url][16..18] == '/ga' ||
    img[:img_url][18..20] == '/ga'
  end

  # Checks to see if the image url has a .gifv extension
  #
  # @param [Hash] img - The image details received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def gifv?(img)
    img[:img_url].end_with?('.gifv')
  end

  # Checks to see if the image url contains more than one image
  #
  # @param [Hash] img - The image details received from Reddit's JSON for a specific post
  # @return [Boolean]
  #
  def multiple_imgs?(img)
    img[:img_url][17..-1].include?(',')
  end
end
