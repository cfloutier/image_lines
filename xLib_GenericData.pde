import java.lang.reflect.Field;

// classe de base des données sauvegardable
class GenericData
{
  GenericData(String chapter_name)
  {
    this.chapter_name = chapter_name;
  }

  String chapter_name = "";
  boolean changed = true;


  ArrayList<GenericData> chapters = new ArrayList<GenericData>();

  void addChapter(GenericData data_chapter)
  {
    chapters.add(data_chapter);
  }

  public void setInt(String name, int value) {

    try {
      Field field = this.getClass().getDeclaredField(name); // Get the field by name
      field.setAccessible(true); // Allow access to private fields if necessary

      if (field.getType() == int.class) { // Check if the field is of type int
        field.setInt(this, value); // Set the field value
        changed = true; // Mark the object as changed
      } else {
        println("Field '" + name + "' is not of type int.");
      }
    }
    catch (NoSuchFieldException e) {

      String class_name = this.getClass().getSimpleName();
      println(class_name + ".'" + name + "' does not exist.");
      // println("Field '" + name + "' does not exist.");
    }
    catch (IllegalAccessException e) {
      e.printStackTrace(); // Handle exceptions gracefully
    }
  }

  // Method to load attributes from a JSONObject using reflection
  public void LoadJson(JSONObject json) {
    if (json == null) return;

    // load primitive fields using reflection
    Field[] fields = this.getClass().getDeclaredFields();

    for (Field field : fields) {
      try {
        field.setAccessible(true); // Allow access to private fields if necessary
        String name = field.getName();
        if (name == "changed" || name =="this$0" ||
            java.lang.reflect.Modifier.isStatic(field.getModifiers()))
        {
          continue;
        }

        if (field.getType() == boolean.class) {
          field.set(this, json.getBoolean(name, field.getBoolean(this)));
        } else if (field.getType() == int.class) {
          field.set(this, json.getInt(name, field.getInt(this)));
        } else if (field.getType() == float.class) {
          field.set(this, json.getFloat(name, field.getFloat(this)));
        } else if (field.getType() == String.class) {
          field.set(this, json.getString(name, (String) field.get(this)));
        }
      }
      catch (IllegalAccessException e) {
        e.printStackTrace(); // Handle exceptions gracefully
      }
    }

    // Load chapters
    for (GenericData chapter : chapters) {
      chapter.LoadJson(json.getJSONObject(chapter.chapter_name));
    }

    changed = true;
  }

  // Method to convert all attributes to a JSONObject using reflection
  public JSONObject SaveJson() {
    JSONObject json = new JSONObject();

    // save primitive fields using reflection
    Field[] fields = this.getClass().getDeclaredFields();

    for (Field field : fields) {
      try {
        field.setAccessible(true); // Allow access to private fields if necessary
        String name = field.getName();
        if (name == "changed" || name =="this$0" ||
            java.lang.reflect.Modifier.isStatic(field.getModifiers()))
        {

          continue;
        }

        Object value = field.get(this);

        if (value instanceof Boolean) {
          json.setBoolean(name, (Boolean) value);
        } else if (value instanceof Integer) {
          json.setInt(name, (Integer) value);
        } else if (value instanceof Float) {
          json.setFloat(name, (Float) value);
        } else if (value instanceof String) {
          json.setString(name, (String) value);
        }
        // else if (value != null) {
        //   json.setString(name, value.toString());
        // }
      }
      catch (IllegalAccessException e) {
        e.printStackTrace(); // Handle exceptions gracefully
      }
    }

    // Save chapters
    for (GenericData chapter : chapters) {
      json.setJSONObject(chapter.chapter_name, chapter.SaveJson());
    }

    return json;
  }

  void CopyFrom(GenericData src)
  {
    Field[] fields = this.getClass().getDeclaredFields();
    for (Field field : fields) {
      try {
        field.setAccessible(true); // Allow access to private fields if necessary
        String name = field.getName();
        if (name == "changed" || name =="this$0" ||
            java.lang.reflect.Modifier.isStatic(field.getModifiers()))
        {
          continue;
        }
        Object value = field.get(this);
        // Copy only primitive types and String
        if (value instanceof Boolean) {
          field.set(this, field.getBoolean(src));
        } else if (value instanceof Integer)
        {
          field.set(this, field.getInt(src));
        } else if (value instanceof Float)
        {
          field.set(this, field.getFloat(src));
        } else if (value instanceof String)
        {
          field.set(this, (String) field.get(src));
        }

        // field.set(this, field.get(src));
      }
      catch (IllegalAccessException e) {
        e.printStackTrace(); // Handle exceptions gracefully
      }
    }

    for (GenericData chapter : chapters) {
      GenericData src_chapter = null;
      for (GenericData c : src.chapters) {
        if (c.chapter_name.equals(chapter.chapter_name)) {
          src_chapter = c;
          break;
        }
      }
      if (src_chapter != null) {
        chapter.CopyFrom(src_chapter);
      }
    }
  }
}
