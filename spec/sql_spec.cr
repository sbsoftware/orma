require "./spec_helper"

class MyModel < TestRecord
  id_column id : Int64
  column name : String
end

describe "MyModel" do
  after_each do
    Orma.reset_db!
  end

  describe ".find" do
    before_each do
      MyModel.continuous_migration!
    end

    it "returns the record by id" do
      model = MyModel.create(name: "Test")

      MyModel.find(model.id).name.should eq("Test")
    end
  end

  describe ".where" do
    before_each do
      MyModel.continuous_migration!
      MyModel.create(name: "Test")
      MyModel.create(name: "Blah")
      MyModel.create(name: "Stefanie")
    end

    it "filters for String values" do
      MyModel.where({"name" => "Test"}).to_a.map(&.name.value).should eq(["Test"])
    end

    it "filters for Int64 values" do
      model = MyModel.where({"name" => "Blah"}).first

      MyModel.where({"id" => model.id.value}).to_a.should eq([model])
    end

    it "filters for mixed values" do
      model = MyModel.where({"name" => "Stefanie"}).first

      MyModel.where({"id" => model.id.value, "name" => "Stefanie"}).to_a.should eq([model])
    end

    it "filters for Array values" do
      models = MyModel.where({"name" => ["Test", "Blah"]}).to_a

      models.map(&.name.value).sort.should eq(["Blah", "Test"])
    end
  end

  describe "#save" do
    context "when the instance has an id" do
      before_each do
        MyModel.continuous_migration!
      end

      it "generates an update statement" do
        my_model = MyModel.create(name: "Katrina")

        my_model.name = "Updated"
        my_model.save

        MyModel.find(my_model.id).name.should eq("Updated")
      end
    end
  end

  describe ".create" do
    before_each do
      MyModel.continuous_migration!
    end

    it "generates an insert statement" do
      MyModel.create(name: "Sabrina")

      MyModel.all.to_a.size.should eq(1)
    end
  end

  describe ".ensure_table_exists!" do
    it "creates the table if missing" do
      MyModel.ensure_table_exists!

      MyModel.create(name: "Sabrina")
      MyModel.all.to_a.size.should eq(1)
    end
  end
end
