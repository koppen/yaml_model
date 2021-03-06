
class Person < YamlModel
  attr_accessor :name
  validates_presence_of :name

  class << self
    alias oldfilename filename
    def filename
      oldfilename + ".test"
    end
  end
end

require 'test/unit'

class YMTest < Test::Unit::TestCase

  def test_new_with_no_attributes
    person = Person.new
    assert(person.new_record?)
    assert(person.name.blank?)
  end

  def test_new_with_name_attribute
    person = Person.new(:name => "David")
    assert(person.new_record?)
    assert_equal("David", person.name)
  end

  def test_save_valid_record
    person = Person.new(:name => "David")
    assert(person.save)
    assert(!person.new_record?)
  end

  def test_save_invalid_record
    person = Person.new
    assert(!person.valid?)
    assert(!person.save)
    assert(person.new_record?)
  end

  def test_save_valid_then_invalid_record
    person = Person.new(:name => "David")
    assert(person.new_record?)
    person.save
    assert(!person.new_record?)
    person.name = ""
    assert(!person.save)
    assert(!person.new_record?)
  end

  def test_create_valid_record
    person = Person.create(:name => "David")
    assert(!person.new_record?)
  end

  def test_create_invalid_record
    person = Person.create
    assert(person.new_record?)
    assert(!person.id)
  end 

  def test_find
    person = Person.create(:name => "David")
    assert(person)
    david = Person.find(person.id)
    assert_equal(person.id, david.id)
  end

  def test_update_attributes_valid
    person = Person.create(:name => "David")
    assert(person)
    person.update_attributes(:name => "David Black")
    assert_equal(person.name, "David Black")
    david = Person.find(person.id)
    assert_equal(david.name, "David Black")
  end

  def test_update_attributes_invalid
    person = Person.create(:name => "David")
    assert(!person.update_attributes(:name => ""))
  end

  def test_saving_first_record_should_create_file
    assert(!File.exists?(Person.filename))
    Person.create(:name => "David")
    assert(File.exists?(Person.filename))
  end

  def test_finding_multiple_records
    a = Person.create(:name => "David")
    b = Person.create(:name => "Joe")
    records = Person.find([a.id, b.id])
    assert_equal(2, records.size)
  end

  def test_dump_with_io_error
    Person.load_records
    with_new_filename("/asdfas/asdfasd/fasdfasd") do
      assert_raises(Errno::ENOENT) { Person.dump_records }
    end
  end

  def test_save_with_io_error_doesnt_work
    person = Person.new(:name => "David")
    with_new_filename("/asdfas/asdfasd/fasdfasd") do
      assert(!person.save)
    end
  end

  def test_before_save
    Person.class_eval { before_save { self.name = self.name.upcase } }
    person = Person.new(:name => "David")
    person.save
    person = Person.find(person.id)
    begin
      assert_equal("DAVID", person.name)
    ensure
      Person.instance_variable_set("@before_save_queue", [])
    end
  end
  
  def test_after_save
    Person.class_eval { after_save { self.name = self.name.reverse } }
    person = Person.new(:name => "David")
    person.save
    person = Person.find(person.id)
    begin
      assert_equal("divaD", person.name)
    ensure
      Person.instance_variable_set("@after_save_queue", [])
    end
  end

  def teardown
    FileUtils.rm(Person.filename) rescue nil
  end

  def with_new_filename(fn)
    old_fn = Person.filename
    sc = (class << Person; self; end)
    sc.class_eval do
      define_method(:filename) { fn }
    end
    begin
      yield
    ensure
      sc.class_eval do
        define_method(:filename) { old_fn }
      end
    end
  end

  def test_all
    # Ensure we're starting from a blank slate
    Person.instance_variable_set('@records', nil)
    david = Person.create(:name => 'David')
    jakob = Person.create(:name => 'Jakob')
    results = Person.all
    assert_equal david, results.first
    assert_equal jakob, results.last
  end
end

