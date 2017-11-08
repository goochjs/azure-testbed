public static HttpResponseMessage Run(HttpRequestMessage req, string name, TraceWriter log)
{
    log.Info("C# HTTP trigger function processed a request.");
 
    var response = new HttpResponseMessage(HttpStatusCode.OK);
    MemoryStream stream = new MemoryStream();
    var httpClient = HttpClientSingle.HttpClient;
    var url = "https://www.niederschlagsradar.de/image.ashx";
    var result = httpClient.GetByteArrayAsync(url).Result;
    response.Content = new ByteArrayContent(result);
    response.Content.Headers.ContentType = new MediaTypeHeaderValue("image/png");
    return response;
}
public static class HttpClientSingle
{
    public static readonly HttpClient HttpClient;
 
    static HttpClientSingle()
    {
        HttpClient = new HttpClient();
    }
}
