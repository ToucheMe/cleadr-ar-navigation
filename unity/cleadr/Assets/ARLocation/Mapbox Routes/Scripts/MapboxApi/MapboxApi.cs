using UnityEngine;
using UnityEngine.Networking;
using System;
using System.Collections;
using System.Globalization;

namespace ARLocation.MapboxRoutes
{
    using Vendor.SimpleJSON;

    [System.Serializable]
    public class MapboxApi
    {
        public string AccessToken;
        public MapboxApiLanguage Language;

        private RouteResponse queryRouteResult;
        public RouteResponse QueryRouteResult => queryRouteResult;

        private GeocodingResponse queryLocalResult;
        public GeocodingResponse QueryLocalResult => queryLocalResult;

        public string errorMessage;
        public string ErrorMessage => errorMessage;

        public MapboxApi(string token, MapboxApiLanguage lang = MapboxApiLanguage.English_US)
        {
            AccessToken = token;
            Language = lang;
        }

        public IEnumerator QueryLocal(string text, bool verbose = false)
        {
            var url = buildQueryLocalUrl(text);

            errorMessage = null;
            queryLocalResult = null;

            if (verbose)
            {
                Debug.Log($"[MapboxApi#QueryLocal]: {url}");
            }

            using (var req = UnityWebRequest.Get(url))
            {
                yield return req.SendWebRequest();

                if (Utils.Misc.WebRequestResultIsError(req))
                {
                    Debug.LogError("[MapboxApi#QueryLocal]: Error -> " + req.error);

                    errorMessage = req.error;
                }
                else
                {
                    if (req.responseCode != 200)
                    {
                        Debug.LogError("[MapboxApi#QueryLocal]: Error -> " + req.downloadHandler.text);
                        var node = JSON.Parse(req.downloadHandler.text);
                        errorMessage = node["message"].Value; //req.downloadHandler.text;
                        queryLocalResult = null;
                    }
                    else
                    {
                        if (verbose)
                        {
                            Debug.Log("[MapboxApi#QueryLocal]: Success -> " + req.downloadHandler.text);
                        }

                        queryLocalResult = GeocodingResponse.Parse(req.downloadHandler.text);
                    }
                }
            }
        }

        string buildQueryLocalUrl(string query)
        {
            var url = Uri.EscapeUriString($"https://api.mapbox.com/geocoding/v5/mapbox.places/{query}.json?access_token={AccessToken}");
            url += $"&language={Language.GetCode()}";

            return url;
        }

        string buildQueryRouteUrl(Location from, Location to, bool alternatives)
        {
            string url = "https://api.mapbox.com/directions/v5/mapbox/walking/";
            string alt = alternatives ? "true" : "false";
            var fromLat = from.Latitude.ToString(CultureInfo.InvariantCulture);
            var fromLon = from.Longitude.ToString(CultureInfo.InvariantCulture);
            var toLat = to.Latitude.ToString(CultureInfo.InvariantCulture);
            var toLon = to.Longitude.ToString(CultureInfo.InvariantCulture);
            var langCode = Language.GetCode();

            url += $"{fromLon}%2C{fromLat}%3B{toLon}%2C{toLat}";
            url += $"?alternatives={alt}";
            url += "&geometries=geojson";
            url += "&steps=true";
            url += $"&access_token={AccessToken}";
            url += $"&language={langCode}";

            return url;
        }

        public IEnumerator QueryRoute(Location from, Location to, bool alternatives = false, bool verbose = false)
        {
            var url = buildQueryRouteUrl(from, to, alternatives);

            errorMessage = null;
            queryRouteResult = null;

            if (verbose)
            {
                Debug.Log($"[MapboxApi#QueryRoute]: {url}");
            }

            using (var req = UnityWebRequest.Get(url))
            {
                yield return req.SendWebRequest();

                if (Utils.Misc.WebRequestResultIsError(req))
                {
                    Debug.LogError("[MapboxApi#QueryRoute]: Error -> " + req.error);

                    errorMessage = req.error;
                }
                else
                {
                    if (verbose)
                    {
                        Debug.Log("[MapboxApi#QueryRoute]: Success -> " + req.downloadHandler.text);
                        Debug.Log("[MapboxApi#QueryRoute]: Success -> " + req.responseCode);
                    }

                    queryRouteResult = RouteResponse.Parse(req.downloadHandler.text);

                    if (queryRouteResult.Code != "Ok")
                    {
                        errorMessage = queryRouteResult.Code;
                        queryRouteResult = null;
                    }
                    else
                    {
                        if (verbose)
                        {
                            Debug.Log("[MapboxApi#QueryRoute]: Parsed result -> " + queryRouteResult);
                        }
                    }
                }
            }
        }
    }
}
