# Full .NET Core 6.0 SDK
# https://hub.docker.com/_/microsoft-dotnet-sdk
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# Copy everything
COPY . ./

RUN dotnet restore 
RUN dotnet publish -c Release -o out 

# Build runtime image 
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
EXPOSE 80
COPY --from=build /app/out .
ENTRYPOINT [ "dotnet","aztfweatherapi.dll"]