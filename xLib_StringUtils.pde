

static class StringUtils
{
  // Formate un entier avec des espaces comme séparateurs de milliers (ex: 1 234 567)
  public static String formatInt(int n)
  {
    String s = str(abs(n));
    String result = "";
    int len = s.length();
    for (int i = 0; i < len; i++)
    {
      if (i > 0 && (len - i) % 3 == 0)
        result += " "; // séparateur de milliers
      result += s.charAt(i);
    }
    return (n < 0 ? "-" : "") + result;
  }

  // Formate une duree en millisecondes en chaine lisible.
  // Ex: 45 ms, 1.5 s, 1m 20s, 2h 15m, 3j 4h
  public static String formatDuration(int ms)
  {
    if (ms < 1000)
      return ms + " ms";

    if (ms < 60000)
    {
      float s = ms / 1000.0;
      if (s < 10.0)
        return nf(s, 1, 1) + " s";
      else
        return (int)s + " s";
    }

    int totalSec = ms / 1000;
    int totalMin = totalSec / 60;
    int totalH   = totalMin / 60;
    int totalD   = totalH   / 24;

    if (totalMin < 60)
    {
      int s = totalSec % 60;
      return s == 0 ? totalMin + " min" : totalMin + "m " + s + "s";
    }

    if (totalH < 24)
    {
      int m = totalMin % 60;
      return m == 0 ? totalH + " h" : totalH + "h " + m + "m";
    }

    int h = totalH % 24;
    return h == 0 ? totalD + " j" : totalD + "j " + h + "h";
  }

  public static boolean isEmpty(String str)
  {
    if (str == null)
      return true;

    if (str == "")
      return true;

    return false;
  }
}

