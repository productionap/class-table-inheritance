require 'rubygems'
require 'minitest/autorun'
require 'minitest/reporters'
require 'active_record'
require 'class-table-inheritance'
require 'yaml'

Minitest::Reporters.use!

ActiveRecord::Base.logger = Logger.new($stdout)
database = YAML.load(File.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(database['sqlite3'])
load(File.dirname(__FILE__) + "/schema.rb")

require 'models/product'
require 'models/book'
require 'models/mod'
require 'models/mod/video'
require 'models/mod/user'
require 'models/manager'

require 'models/key_card'
require 'models/school/student'
require 'models/school/teacher'
