require 'cgi'
require 'rubygems'
require 'httparty'
require 'mash'
require 'values_to_proper_class'

module Kernel
  
  # if an object is not already an array, place it inside one
  def ensure_a
    self.is_a?(Array) ? self : [self]
  end

end

class CalorieKing
  
  include HTTParty
  
  # Test Developer Key - smaller dataset
  # basic_auth '84294d7ae4454189bf2a3ebc37a0e421', ''
  
  base_uri 'http://foodsearch1.webservices.calorieking.com/rest'
  
  def self.urlencode(text)
    CGI::escape(text)
  end

  # enter a search term and receive a list of possible matches within an array of categories
  
  # irbxample:  
  # CalorieKing.basic_auth '84294d7ae4454189bf2a3ebc37a0e421', '' (in Rails, put this in an initializer - config/initializers/calorie_king.rb)
  # categories = CalorieKing.search 'Big Mac'
  
  # >> categories.first.name
  #   => "McDonald's"
  
  # >> categories.first.foods.first.name
  #   => "Sandwiches, Big Mac"
  
  # >> categories.first.foods.first.id
  #   => "6adc1bda-24f6-42a8-87ee-4de0ba87ac96"

  def self.search(term)
    begin
      categories = get("/search/#{urlencode(term)}")['searchresults']['category'].ensure_a
      categories = categories.collect do |c| 
        Mash.new({ 
          "name" => c['name'],
          "foods" => c['foods']['food'].ensure_a.collect {|f| {"name" => f["display"], "id" => f["id"]} }
        })
      end
      categories
    rescue
      puts "Sorry, but we couldn't find anything remotely close to that food."
    end
  end
  
  # enter a food id and receive a hash containing the food, it's available serving types (cup, gram, teaspoon) and associated nutritional data
  # nutritional data will be returned in appropriate class (integers, floats, etc.) rather than just as a string
  
  # irb example:
  # CalorieKing.basic_auth '84294d7ae4454189bf2a3ebc37a0e421', '' (in Rails, put this in an initializer - config/initializers/calorie_king.rb)
  # food = CalorieKing.find_by_id "6adc1bda-24f6-42a8-87ee-4de0ba87ac96"
  
  # >> food.name
  #   => "McDonald's: Sandwiches & Burgers: Sandwiches, Big Mac"
  
  # >> food.servings.first.name
  #   => "sandwich (7.5 oz)"
  
  # >> food.servings.first.nutrients.calories
  #   => 540
  
  def self.find_by_id(id)
    begin
      food = get("/foods/#{id}")['food']
      food["servings"] = food['servings']['serving'].ensure_a
      Mash.new(food.values_to_proper_class)
    rescue
      puts "Sorry, but we couldn't find a food with that id."
    end
  end
  
end