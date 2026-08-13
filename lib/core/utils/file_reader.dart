export 'file_reader_unsupported.dart'
    if (dart.library.io) 'file_reader_io.dart'
    if (dart.library.html) 'file_reader_web.dart';
