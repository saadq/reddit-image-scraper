require 'sinatra'
require 'open-uri'
require 'json'

class App < Sinatra::Base
  get '/' do
    erb :form
  end

  post '/results' do
    @imgs = scrape_reddit
    erb :results
  end

  # Main scraper method that takes the user
  # input from the form and scrapes a subreddit
  # from reddit.com
  def scrape_reddit
    sub   = params[:subreddit]
    score = params[:score].to_i
    count = params[:submissions].to_i

    url = "https://reddit.com/r/#{sub}/.json?limit=#{count}"
    res = open(url, "User-Agent" => "Ruby/#{RUBY_VERSION}").read
    reddit_json = JSON.parse(res)

    images = []

    count.times do |n|
      img = {
        title:    reddit_json['data']['children'][n]['data']['title'],
        img_url:  reddit_json['data']['children'][n]['data']['url'],
        post_url: reddit_json['data']['children'][n]['data']['permalink'],
        score:    reddit_json['data']['children'][n]['data']['score']
      }

      if valid_img?(img) && img[:score] >= score
        normalize_url(img[:img_url])
        images << img
      end
    end

    images
  end

  # Checks to see if the image url is an
  # imgur link and that it is only a single image
  def valid_img?(img)
    img != nil &&
    !img.empty? &&
    (imgur?(img) || ireddit?(img)) &&
    !multiple_imgs?(img) &&
    !gifv?(img)
  end

  # Checks to see if the image url is an imgur link
  def imgur?(img)
    img[:img_url][7..11] == 'imgur' ||
    img[:img_url][7..11] == 'i.img' ||
    img[:img_url][7..11] == 'm.img'
  end

  # Checks to see if the image url is an ireddit link
  def ireddit?(img)
    img[:img_url][8..16] == 'i.redd.it'
  end

  # Checks to see if the image url contains more than one image
  def multiple_imgs?(img)
    album?(img) ||
    gallery?(img) ||
    img[:img_url][17..-1].include?(',')
  end

  # Checks to see if the image url is an album
  def album?(img)
    img[:img_url][16..18] == '/a/' ||
    img[:img_url][18..20] == '/a/'
  end

  # Checks to see if the image url is a gallery
  def gallery?(img)
    img[:img_url][16..18] == '/ga' ||
    img[:img_url][18..20] == '/ga'
  end

  # Checks to see if the image url has a .gifv extension
  def gifv?(img)
    img[:img_url].end_with?('.gifv')
  end

  # Normalizes an imgur url to start with i.imgur
  def normalize_url(img_url)
    if img_url[7..11] == 'imgur'
      img_url.insert(7, 'i.')
      if (
        !img_url.end_with?('.gif') ||
        !img_url.end_with('.jpg') ||
        !img_url.end_with('.png') ||
        !img_url.end_with('.jpeg')
      )
        img_url << '.gif'
      end
    end
  end
end
