require 'couchrest'
require 'rubygems'
require 'json'
require 'sinatra'

module Api
  class VisitorsController < ApplicationController
    protect_from_forgery with: :null_session
    before_filter :init_db
	
	#uri = 'mongodb://localhost:27017'
    #database = 'db'

	#db=nil
 
#    def get_couch_db(creds)
#	  url = creds['url']
#	  if !url.end_with?('/')
#		url = url + '/'
#	  end
#      url = url + 'mydb'
#      puts 'Using URL: ' + url
#      db = CouchRest.database!(url)
#    end
 
    def init_db
      @db = CouchRest.database!("https://03368d13-7aac-42c8-a9a4-f77ed3d7ab80-bluemix:3f85a56c0963be9b09027a522634077c4a1b6393f533f45f170706dd2abb6722@03368d13-7aac-42c8-a9a4-f77ed3d7ab80-bluemix.cloudant.com/mydb")
    # if ENV['VCAP_SERVICES']
    #   svcs = JSON.parse ENV['VCAP_SERVICES']  
    #   couchrest = svcs.detect { |k,v| k =~ /^ruby-rails/ }.last.first
    #   creds = couchrest['credentials']
    #   uri = creds['url']
    #   @db = uri[%r{/([^/\?]+)(\?|$)}, 1]
    # end
    end

    # POST /api/visitors
    def create
      userName = params[:name]
      if @db.nil?
        render text: "Hello " + userName + "!"
      else
        response = @db.save_doc({"name": userName})
        render text: "Hello " + userName + "! I added you to the database."
      end
    end

    # GET /api/visitors
    def index
      if @db.nil?
        render json: [], status: 200
      else
        docs = @db.all_docs(params={"include_docs":"true"})["rows"]
        names = docs.map { |d| d["doc"]["name"] }
        render json: JSON.dump(names), status: 200
      end
    end
  end
end