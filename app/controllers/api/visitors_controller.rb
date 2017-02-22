require 'couchrest'
require 'rubygems'
require 'json'
require 'dotenv/rails'

Dotenv.load()

module Api
  class VisitorsController < ApplicationController
    protect_from_forgery with: :null_session
    before_filter :init_db

    def init_db
      if @db
        create_view(@db)
      else
	    if ENV['VCAP_SERVICES']
          begin
            svcs = JSON.parse ENV['VCAP_SERVICES']
            cloudant = svcs.detect { |k,v| k =~ /^cloudantNoSQLDB/ }.last.first
            creds = cloudant['credentials']
            @db = get_couch_db(creds)
          rescue
            puts 'No database found'
        else
          if ENV['CLOUDANT_URL']
            @db = CouchRest.database!(ENV['CLOUDANT_URL'])
          end
        end
		create_view(@db)
      end
    end

    # Helper function to construct the proper URL
    # to the Couch DB.
    # URL should be http(s)://username:password@user.cloudant.com/mydb
    def get_couch_db(creds)
      url = creds['url']
      if !url.end_with?('/')
        url = url + '/'
      end
      url = url + 'mydb'

      puts 'Using URL: ' + url
      #This will create the DB if it does not exist, however it will fail if you do not have permissions
      CouchRest.database!(url)
    end

    # Helper function to create the view if it does not already exist
    def create_view(db)
      begin
        db.get('_design/todos')
      rescue RestClient::ResourceNotFound => nfe
        db.save_doc({
          "_id" => "_design/todos",
          :views => {
            :allTodos => {
              :reduce => "_count",
              :map => "function(doc){if(doc.name != null){emit(doc.order,{name: doc.name})}}"
            }
          }
          })
      end
    end

    # /* Endpoint to greet and add a new visitor to database.
    # * Send a POST request to localhost:3000/api/visitors with body
    # * {
    # * 	"name": "Bob"
    # * }
    # */
    def create
      userName = params[:name]
      if @db.nil?
        render text: "Hello " + userName + "!"
      else
        response = @db.save_doc({"name": userName})
        render text: "Hello " + userName + "! I added you to the database."
      end
    end

    # /**
    #  * Endpoint to get a JSON array of all the visitors in the database
    #  * REST API example:
    #  * <code>
    #  * GET http://localhost:3000/api/visitors
    #  * </code>
    #  *
    #  * Response:
    #  * [ "Bob", "Jane" ]
    #  * @return An array of all the visitor names
    #  */
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
