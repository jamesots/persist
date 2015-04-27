A really basic persistence thing for dart and sqljocky.
Define an Entity, create an EntityDao, create, read, update and delete 
entities. Doesn't manage relationships or anything clever like that.

    @Entity(table: "thing")
    class Thing {
      @Attribute(primaryKey: true)
      String userId;
      @Attribute()
      String name;
      @Attribute()
      int age;
      
      Thing(this.userId, this.name, this.age);
      Thing.empty();
    }
    
    var pool = new ConnectionPool(...);
    var dao = new EntityDao<Thing>(pool);
    
    var thing = new Thing("bob", "Bob", 25);
    await dao.insertNew(thing);
    
    var things = await dao.readAll();
    
    thing.age = 25;
    await dao.update(thing);
    
    await dao.delete(thing);
