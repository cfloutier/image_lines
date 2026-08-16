
class DataGlobal
{
  DataGlobal()
  {
    println("xLib version : " + get_xlib_version());

    page = new DataPage();
    chapters.add(page);
  }

  String name = "";
  String settings_path = "";

  boolean need_update_ui = false;

  // this field is modified by the UIPanel
  // on any UI change. it is used
  boolean changed = true;

  float width = 800;
  float height = 600;

  DataPage page = new DataPage();

  void reset()
  {
    println("error calling base reset");
  }

  void setSize(float width, float height)
  {
    if (this.width != width)
    {
      changed = true;
      this.width = width;
    }

    if (this.height != height)
    {
      changed = true;
      this.height = height;
    }
  }

  ArrayList<GenericData> chapters = new ArrayList<GenericData>();

  void addChapter(GenericData data_chapter)
  {
    chapters.add(data_chapter);
  }

  String getFileNameWithoutExtension(String path) {
    File file = new File(path);
    String fileName = file.getName();
    int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex > 0) {
      return fileName.substring(0, dotIndex);
    } else {
      return fileName;
    }
  }

  void LoadSettings(String path)
  {
    println("loading settings : " + path);
    reset();

    settings_path = path;
    data.name = getFileNameWithoutExtension(path);
    JSONObject json = loadJSONObject(path);

    for (GenericData chapter : chapters) {
      chapter.LoadJson(json.getJSONObject(chapter.chapter_name));
    }

    changed = true;
  }

  void SaveSettings(String path)
  {
    println("Save settings " + path);

    data.name = getFileNameWithoutExtension(path);
    settings_path = path;
    JSONObject json = new JSONObject();

    for (GenericData chapter : chapters) {
      json.setJSONObject(chapter.chapter_name, chapter.SaveJson());
    }

    saveJSONObject(json, path);
    changed = true;
  }

  void need_ui_update()
  {
    need_update_ui = true;
  }

  boolean any_change()
  {
    if (changed)
      return true;

    for (GenericData chapter : chapters) {
      if (chapter.changed)
        return true;
    }

    return false;
  }

  void reset_all_changes()
  {
    changed = false;
    for (GenericData chapter : chapters) {
      chapter.changed = false;
    }
  }
}
