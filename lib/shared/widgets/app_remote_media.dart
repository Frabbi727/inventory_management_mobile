import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class AppRemoteMedia {
  AppRemoteMedia._();

  static const defaultHeaders = <String, String>{
    'Accept':
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    'User-Agent': 'inventory-management-sales-app',
  };
}

class AppCachedNetworkImage extends StatefulWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<AppCachedNetworkImage> createState() => _AppCachedNetworkImageState();
}

class _AppCachedNetworkImageState extends State<AppCachedNetworkImage> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImageBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return widget.errorWidget ?? const SizedBox.shrink();
        }

        return Image.memory(snapshot.data!, fit: widget.fit);
      },
    );
  }

  Future<Uint8List> _loadImageBytes() async {
    final response = await http
        .get(Uri.parse(widget.imageUrl), headers: AppRemoteMedia.defaultHeaders)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load image: ${response.statusCode}');
    }

    return response.bodyBytes;
  }
}

class AppNetworkSvg extends StatefulWidget {
  const AppNetworkSvg({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<AppNetworkSvg> createState() => _AppNetworkSvgState();
}

class _AppNetworkSvgState extends State<AppNetworkSvg> {
  late Future<String> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _loadSvg();
  }

  Future<String> _loadSvg() async {
    final response = await http
        .get(Uri.parse(widget.url), headers: AppRemoteMedia.defaultHeaders)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load SVG: ${response.statusCode}');
    }

    return utf8.decode(response.bodyBytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _svgFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return widget.errorWidget ?? const SizedBox.shrink();
        }

        return SvgPicture.string(snapshot.data!, fit: widget.fit);
      },
    );
  }
}
