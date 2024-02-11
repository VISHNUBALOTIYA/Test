var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

var app = builder.Build();


app.MapGet("/message", () =>
{
return "welcome to 2024";
});

app.Run();

