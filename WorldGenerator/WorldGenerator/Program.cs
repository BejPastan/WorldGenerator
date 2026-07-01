using WorldGenerator.Repos;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Services;
using WorldGenerator.Services.Interfaces;
using WorldGenerator.Utils;
using WorldGenerator.Utils.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddSingleton<ISecretRepo, LocalSecretRepo>();
builder.Services.AddSingleton<IDBHandler, DBController>();

builder.Services.AddScoped<IMapRepo, MapRepo>();
builder.Services.AddScoped<IMapService, MapService>();

builder.Services.AddControllers();
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(new NetTopologySuite.IO.Converters.GeoJsonConverterFactory());
});

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/openapi/v1.json","WorldGeneratorAPI");
    });
}


app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
