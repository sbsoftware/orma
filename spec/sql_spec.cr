require "./spec_helper"
require "./fake_db"

class MyModel < FakeRecord
  column name : String
end

describe "MyModel" do
  before_each do
    FakeDB.reset
  end

  after_each do
    FakeDB.assert_empty!
  end

  describe ".find" do
    it "generates the correct SQL query" do
      FakeDB.expect("SELECT * FROM my_models WHERE id=3 LIMIT 1").set_result([{"id" => 3_i64, "name" => "Test"} of String => DB::Any])
      model = MyModel.find(3)
    end
  end

  describe ".where" do
    it "generates the correct SQL query for String values" do
      FakeDB.expect("SELECT * FROM my_models WHERE name='Test'")
      models = MyModel.where({"name" => "Test"}).to_a
    end

    it "generates the correct SQL query for Int64 values" do
      FakeDB.expect("SELECT * FROM my_models WHERE id=122")
      models = MyModel.where({"id" => 122_i64}).to_a
    end

    it "generates the correct SQL query for mixed values" do
      FakeDB.expect("SELECT * FROM my_models WHERE id=122 AND name='Stefanie'")
      models = MyModel.where({"id" => 122_i64, "name" => "Stefanie"}).to_a
    end

    it "generates the correct SQL query for Array values" do
      FakeDB.expect("SELECT * FROM my_models WHERE name IN ('Test','Blah')")
      models = MyModel.where({"name" => ["Test", "Blah"]}).to_a
    end
  end

  describe "#save" do
    context "when the instance has an id" do
      it "generates an update statement" do
        my_model = MyModel.new(id: 122_i64, name: "Katrina")
        FakeDB.expect("UPDATE my_models SET name='Katrina' WHERE id=122")
        my_model.save
      end
    end
  end

  describe ".create" do
    it "generates an insert statement" do
      FakeDB.expect("INSERT INTO my_models(name) VALUES ('Sabrina')")
      my_model = MyModel.create(name: "Sabrina")
    end
  end

  describe ".ensure_table_exists!" do
    it "should execute the correct CREATE TABLE statement" do
      FakeDB.expect("CREATE TABLE IF NOT EXISTS my_models(id BIGSERIAL PRIMARY KEY, name VARCHAR)")
      MyModel.ensure_table_exists!
    end
  end
end
