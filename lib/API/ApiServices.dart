import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'AppExceptions.dart';
import 'BaseApiServices.dart';
import 'package:http/http.dart' as http;
// Your provided OAuth and token URLs
// final authorizationEndpoint = Uri.parse('https://apex.oracle.com/pls/apex/metaxperts/oauth');
//   final tokenEndpoint = Uri.parse('https://apex.oracle.com/pls/apex/metaxperts/oauth/token');
// // Your provided client ID and secret
//   final identifier = 'PEdOhv7Iqu4sCtQsRzbibQ..';
//   final secret = '122w1TFTxsqTwY1-nhV9fA..';

class ApiServices extends BaseApiServices {

  final tokenEndpoint = Uri.parse('https://g77e7c85ff59092-db17lrv.adb.ap-singapore-1.oraclecloudapps.com/ords/metaxperts/oauth/token');
  final tokenEndpoint1 = Uri.parse('http://103.149.32.30:8080/ords/metaxperts/oauth/token');

// Your provided client ID and secret
  final identifier = 'LdvnAhHGx6Li4XXJTfIW0w..';
  final identifier1 = '6v6MJiirvoS1pRo1wMyhdg..';
  final secret = 'IMjAqywrUane3NA_qGVTWQ..';
  final secret1 = 'TlPiTfNr0vSKLBJ7hwRGCA..';

// This is a URL on your application's server. The authorization server will redirect the resource owner here after they authorize.
//   final redirectUrl = Uri.parse('http://localhost:8000/callback');

  Future<oauth2.Client> getClient(Uri tokenEndpoint, String identifier, String secret) async {
    return await oauth2.clientCredentialsGrant(
      tokenEndpoint,
      identifier,
      secret,
    );
  }

  Future<oauth2.Client> getClient1(Uri tokenEndpoint1, String identifier1, String secret1) async {
    return await oauth2.clientCredentialsGrant(
      tokenEndpoint1,
      identifier1,
      secret1,
    );
  }

  @override
  Future<dynamic> postApi(var data, dynamic url) async {


    dynamic responseJson;
    dynamic responseJson1;

    try {
      final client = await getClient(tokenEndpoint, identifier, secret);
      final response = await client.post(Uri.parse(url), body: data,).timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } catch (e) {
      print("Error with first API. Trying second API.");
      final client1 = await getClient(tokenEndpoint1, identifier1, secret1);
      final response1 = await client1.post(Uri.parse(url), body: data,).timeout(const Duration(seconds: 10));
      responseJson1 = returnResponse(response1);
    }

    return responseJson ?? responseJson1;
  }


@override

Future<dynamic> getApi(dynamic url) async {
  dynamic responseJson;
  dynamic responseJson1;

  try {
    // Try fetching data from the first API
    final client = await getClient(tokenEndpoint, identifier, secret);
    final response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    responseJson = jsonDecode(response.body);
    responseJson = responseJson['items'];
  } catch (e) {
    print("Error with first API. Trying second API.");

    try {
      // If the first API fails, try fetching data from the second API
      final client1 = await getClient(tokenEndpoint1, identifier1, secret1);
      final response1 = await client1.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      responseJson1 = jsonDecode(response1.body);
      responseJson1 = responseJson1['items'];
    } catch (e) {
      print("Error with second API as well. Unable to fetch data from both APIs.");
    }
  }

  // Return data from the first successful API call or null if both fail
  return responseJson ?? responseJson1;
}



  @override
  Future<dynamic> putApi(var data, dynamic url) async {
    final client = await getClient(tokenEndpoint, identifier, secret);
    final client1 = await getClient(tokenEndpoint1, identifier1, secret1);
    dynamic responseJson;
    dynamic responseJson1;

    try {
      final response = await client.put(Uri.parse(url), body: data,).timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } catch (e) {
      print("Error with first API. Trying second API.");
      final response1 = await client1.put(Uri.parse(url), body: data,).timeout(const Duration(seconds: 10));
      responseJson1 = returnResponse(response1);
    }

    return responseJson ?? responseJson1;
  }




  Future<bool> masterPost(Map<String, dynamic> data, dynamic url) async {
    if (kDebugMode) {
      print(url);
      print(data);
    }

    try {
      final client = await getClient(tokenEndpoint, identifier, secret);
      final response = await client.post(Uri.parse(url), body: data,).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Post failed with first API');
      }
    } catch (e) {
      try {
        final client1 = await getClient(tokenEndpoint1, identifier1, secret1);
        print("Error with first API. Trying second API.");
        final response1 = await client1.post(Uri.parse(url), body: data,).timeout(const Duration(seconds: 10));

        if (response1.statusCode == 200) {
          return true;
        } else {
          print("ERROR ${response1.statusCode.toString()}");
          return false;
        }
      } catch (e) {
        print("Error with second API as well.");
        return false;
      }
    }
  }


  dynamic returnResponse(http.Response response){
    switch(response.statusCode){
      case 200:
        dynamic responseJson = jsonDecode(response.body);
        return responseJson ;
      case 400:
        dynamic responseJson = jsonDecode(response.body);
        return responseJson ;

      default :
        throw FetchDataException('Error accoured while communicating with server '+response.statusCode.toString()) ;
    }
  }


  Future<bool> masterPostWithImage(Map<dynamic, dynamic> data, dynamic url, Uint8List? body) async {
    if (kDebugMode) {
      print(url);
      print(data);
    }

    try {
      // Get the OAuth2 client
      final client = await getClient(tokenEndpoint, identifier, secret);

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add fields from the data map
      data.forEach((key, value) {
        request.fields[key.toString()] = value.toString();
      });

      // Add image if provided
      if (body != null) {
        request.files.add(http.MultipartFile.fromBytes('body', body, filename: 'shop_image.jpg',),);
      }

      // Use the client to send the request
      final streamedResponse = await client.send(request);

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Successful response, you might want to handle the response further
        var result = response.body;
        print('Image uploaded successfully. Response: $result');

        if (kDebugMode) {
          print(result);
        }
        return true;
      } else {
        throw Exception('Post failed with first API');
      }
    } catch (e) {
      print("Error with first API. Trying second API.");

      // Get the OAuth2 client
      final client1 = await getClient(tokenEndpoint1, identifier1, secret1);

      final request1 = http.MultipartRequest('POST', Uri.parse(url));

      // Add fields from the data map
      data.forEach((key, value) {
        request1.fields[key.toString()] = value.toString();
      });

      // Add image if provided
      if (body != null) {
        request1.files.add(http.MultipartFile.fromBytes('body', body, filename: 'shop_image.jpg',),);
      }

      // Use the client to send the request
      final streamedResponse1 = await client1.send(request1);

      // Get the response
      final response1 = await http.Response.fromStream(streamedResponse1);

      if (response1.statusCode == 200) {
        // Successful response, you might want to handle the response further
        var result1 = response1.body;
        print('Image uploaded successfully. Response: $result1');

        if (kDebugMode) {
          print(result1);
        }
        return true;
      } else {
        // Unsuccessful response
        print("ERROR ${response1.statusCode.toString()}");
        return false;
      }
    }
  }

  Future<bool> masterPostWithGPX(Map<dynamic, dynamic> data, dynamic url, Uint8List? body) async {
    if (kDebugMode) {
      print(url);
      print(data);
    }

    try {
      // Get the OAuth2 client
      final client = await getClient(tokenEndpoint, identifier, secret);

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add fields from the data map
      data.forEach((key, value) {
        request.fields[key.toString()] = value.toString();
      });

      // Add image if provided
      if (body != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'body',
            body,
            filename: 'shop_image.gpx', // Adjust the filename as needed
          ),
        );
      }

      // Use the client to send the request
      final streamedResponse = await client.send(request);

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Successful response, you might want to handle the response further
        var result = response.body;
        print('Image uploaded successfully. Response: $result');

        if (kDebugMode) {
          print(result);
        }
        return true;
      } else {
        throw Exception('Post failed with first API');
      }
    } catch (e) {
      print("Error with first API. Trying second API.");

      // Get the OAuth2 client
      final client1 = await getClient(tokenEndpoint1, identifier1, secret1);

      final request1 = http.MultipartRequest('POST', Uri.parse(url));

      // Add fields from the data map
      data.forEach((key, value) {
        request1.fields[key.toString()] = value.toString();
      });

      // Add image if provided
      if (body != null) {
        request1.files.add(
          http.MultipartFile.fromBytes(
            'body',
            body,
            filename: 'shop_image.gpx', // Adjust the filename as needed
          ),
        );
      }

      // Use the client to send the request
      final streamedResponse1 = await client1.send(request1);

      // Get the response
      final response1 = await http.Response.fromStream(streamedResponse1);

      if (response1.statusCode == 200) {
        // Successful response, you might want to handle the response further
        var result1 = response1.body;
        print('Image uploaded successfully. Response: $result1');

        if (kDebugMode) {
          print(result1);
        }
        return true;
      } else {
        // Unsuccessful response
        print("ERROR ${response1.statusCode.toString()}");
        return false;
      }
    }
  }

}
