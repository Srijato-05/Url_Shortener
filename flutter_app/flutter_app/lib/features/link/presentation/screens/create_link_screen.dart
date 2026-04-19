import 'package:flutter/material.dart';

class CreateLinkScreen extends StatefulWidget {
  @override
  _CreateLinkScreenState createState() => _CreateLinkScreenState();
}

class _CreateLinkScreenState extends State<CreateLinkScreen> {
  final TextEditingController _controller = TextEditingController();
  String shortUrl = "";

  void generateLink() {
    setState(() {
      shortUrl = "https://short.ly/abc123";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("URL Shortener"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter Long URL",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: generateLink,
              child: Text("Shorten URL"),
            ),

            SizedBox(height: 20),

            Text(
              "Short URL: $shortUrl",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}