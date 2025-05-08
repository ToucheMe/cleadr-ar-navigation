namespace ARLocation.MapboxRoutes
{
    public enum MapboxApiLanguage
    {
        Arabic,
        Chinese_Mandarin,
        Czech_Czech,
        Welsh_United,
        Danish,
        German,
        Greek_Greece,
        English_Australia,
        English_Welsh,
        English_UK,
        English_India,
        English_Singapore,
        English_US,
        Spanish_Mexico,
        Spanish_US,
        Spanish_Spain,
        Estonian,
        Finnish,
        French_Canada,
        French,
        Hebrew,
        Hungarian,
        Indonesian,
        Icelandic_Iceland,
        Italian,
        Japanese,
        Korean,
        Dutch_Belgium,
        Dutch,
        Norwegian_Bokmal,
        Polish,
        Portuguese_Brazil,
        Portuguese_Portugal,
        Romanian,
        Russian,
        Slovak_Slovakia,
        Slovene,
        Swedish,
        Thai_Thailand,
        Turkish,
        Ukrainian,
        Vietnamese,
        Chinese_China,

    }

    public static class MapboxApiLanguageExtensions
    {
        public static string GetCode(this MapboxApiLanguage me)
        {
            switch (me)
            {
                case MapboxApiLanguage.Arabic:
                    return "ar";
                case MapboxApiLanguage.Chinese_Mandarin:
                    return "cmn-CN";
                case MapboxApiLanguage.Czech_Czech:
                    return "cs-CZ";
                case MapboxApiLanguage.Welsh_United:
                    return "cy-GB";
                case MapboxApiLanguage.Danish:
                    return "da";
                case MapboxApiLanguage.German:
                    return "de";
                case MapboxApiLanguage.Greek_Greece:
                    return "el-GR";
                case MapboxApiLanguage.English_Australia:
                    return "en-AU";
                case MapboxApiLanguage.English_Welsh:
                    return "en-GB-WLS";
                case MapboxApiLanguage.English_UK:
                    return "en-GB";
                case MapboxApiLanguage.English_India:
                    return "en-IN";
                case MapboxApiLanguage.English_Singapore:
                    return "en-SG";
                case MapboxApiLanguage.English_US:
                    return "en";
                case MapboxApiLanguage.Spanish_Mexico:
                    return "es-MX";
                case MapboxApiLanguage.Spanish_US:
                    return "es-US";
                case MapboxApiLanguage.Spanish_Spain:
                    return "es";
                case MapboxApiLanguage.Estonian:
                    return "et";
                case MapboxApiLanguage.Finnish:
                    return "fi";
                case MapboxApiLanguage.French_Canada:
                    return "fr-CA";
                case MapboxApiLanguage.French:
                    return "Fr";
                case MapboxApiLanguage.Hebrew:
                    return "he";
                case MapboxApiLanguage.Hungarian:
                    return "hu";
                case MapboxApiLanguage.Indonesian:
                    return "id";
                case MapboxApiLanguage.Icelandic_Iceland:
                    return "is-IS";
                case MapboxApiLanguage.Italian:
                    return "it";
                case MapboxApiLanguage.Japanese:
                    return "ja";
                case MapboxApiLanguage.Korean:
                    return "ko";
                case MapboxApiLanguage.Dutch_Belgium:
                    return "nl-BE";
                case MapboxApiLanguage.Dutch:
                    return "nl";
                case MapboxApiLanguage.Norwegian_Bokmal:
                    return "no";
                case MapboxApiLanguage.Polish:
                    return "pl";
                case MapboxApiLanguage.Portuguese_Brazil:
                    return "pt-BR";
                case MapboxApiLanguage.Portuguese_Portugal:
                    return "pt-PT";
                case MapboxApiLanguage.Romanian:
                    return "ro";
                case MapboxApiLanguage.Russian:
                    return "ru";
                case MapboxApiLanguage.Slovak_Slovakia:
                    return "sk-SK";
                case MapboxApiLanguage.Slovene:
                    return "sl";
                case MapboxApiLanguage.Swedish:
                    return "sv";
                case MapboxApiLanguage.Thai_Thailand:
                    return "th-TH";
                case MapboxApiLanguage.Turkish:
                    return "tr";
                case MapboxApiLanguage.Ukrainian:
                    return "uk";
                case MapboxApiLanguage.Vietnamese:
                    return "vi";
                case MapboxApiLanguage.Chinese_China:
                    return "zh-CN";
            }

            return "en";
        }
    }
}
