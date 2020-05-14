class Dog
    attr_accessor :name, :breed
    attr_reader :id

    def initialize (name:, breed:, id: nil)
        @name = name 
        @breed = breed
        @id = id
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
        )
        SQL

        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL
        DROP TABLE IF EXISTS dogs
        SQL

        DB[:conn].execute(sql)
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?, ?)
            SQL

            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
            self
        end
    end

    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"

        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def self.create(name:, breed:)
        new_dog = Dog.new(name:name, breed:breed)
        new_dog.save
        new_dog
    end

    def self.new_from_db(row)
        new_dog = self.new(name: row[1], breed: row[2], id: row[0])
        new_dog
    end

    def self.find_by_id(id)
        sql = <<-SQL
        SELECT * FROM dogs 
        WHERE id = ?
        SQL
        
        DB[:conn].execute(sql, id).map do |row|
            Dog.new_from_db(row)
        end.first
    end

    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
        SELECT * FROM dogs 
        WHERE name = ? AND breed = ? LIMIT 1
        SQL

        dog = DB[:conn].execute(sql, name, breed)
        if !dog.empty?
            dog_info = dog[0]
            dog = Dog.new(id: dog_info[0], name: dog_info[1], breed: dog_info[2])
        else
            dog = self.create(name: name, breed: breed)
        end
        dog
    end

    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM dogs 
        WHERE name = ?
        SQL

        DB[:conn].execute(sql, name).map do |row|
            Dog.new_from_db(row)
        end.first
    end

end