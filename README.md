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
    var dao = new EntityDao<Thing>(Thing, pool);
    
    var thing = new Thing("bob", "Bob", 25);
    dao.insertNew(thing).then(...);
    
    var things = dao.readAll().then(...);
    
    thing.age = 25;
    dao.update(thing).then(...);
    
    dao.delete(thing).then(...);
