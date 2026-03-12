import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const ScreenApiApp());
}

class ScreenApiApp extends StatelessWidget {
  const ScreenApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Screen API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PhotoPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => _openPicker(context),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Открыть',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class PhotoPickerSheet extends StatefulWidget {
  const PhotoPickerSheet({super.key});

  @override
  State<PhotoPickerSheet> createState() => _PhotoPickerSheetState();
}

class _PhotoPickerSheetState extends State<PhotoPickerSheet> {
  late final PhotoPickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PhotoPickerController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FractionallySizedBox(
              heightFactor: 0.95,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 90,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6D6D6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Выберите фотографии',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          height: 1.02,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF101114),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(child: _PickerBody(controller: _controller)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PickerBody extends StatelessWidget {
  const _PickerBody({required this.controller});

  final PhotoPickerController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!controller.hasGalleryAccess) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Color(0xFF9D9D9D),
            ),
            const SizedBox(height: 16),
            const Text(
              'Нужно разрешение на доступ к фото, чтобы показать галерею устройства.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, height: 1.35),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.openSettings,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2F6BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: const Text('Открыть настройки'),
            ),
          ],
        ),
      );
    }

    final items = controller.gridItems;

    return RefreshIndicator(
      onRefresh: controller.reload,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return _ActionTile.camera(onTap: controller.pickFromCamera);
                }
                if (index == 1) {
                  return _ActionTile.gallery(onTap: controller.pickFromGallery);
                }
                if (index == 2) {
                  return _ActionTile.file(onTap: controller.pickFile);
                }

                final item = items[index - 3];
                return _MediaGridTile(
                  controller: controller,
                  item: item,
                  onTap: () => controller.toggleSelection(item),
                );
              }, childCount: items.length + 3),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'На устройстве пока нет изображений. Можно сделать фото или выбрать файл выше.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C6C6C),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.background,
    this.foreground = const Color(0xFF1A1A1A),
    this.overlay,
  });

  factory _ActionTile.camera({required Future<void> Function() onTap}) {
    return _ActionTile(
      onTap: onTap,
      label: 'Камера',
      icon: Icons.photo_camera_rounded,
      foreground: Colors.white,
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0C2F31), Color(0xFF43CFC0), Color(0xFF0F4F52)],
      ),
      overlay: const _CameraBackdrop(),
    );
  }

  factory _ActionTile.gallery({required Future<void> Function() onTap}) {
    return _ActionTile(
      onTap: onTap,
      label: 'Галерея',
      icon: Icons.collections_outlined,
      background: const LinearGradient(
        colors: [Color(0xFFEDEDED), Color(0xFFE9E9E9)],
      ),
    );
  }

  factory _ActionTile.file({required Future<void> Function() onTap}) {
    return _ActionTile(
      onTap: onTap,
      label: 'Файл',
      icon: Icons.insert_drive_file_outlined,
      background: const LinearGradient(
        colors: [Color(0xFFEDEDED), Color(0xFFE9E9E9)],
      ),
    );
  }

  final Future<void> Function() onTap;
  final String label;
  final IconData icon;
  final Gradient background;
  final Color foreground;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: background,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              overlay ?? const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 42, color: foreground),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraBackdrop extends StatelessWidget {
  const _CameraBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -28,
          top: 10,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          right: -12,
          bottom: -16,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaGridTile extends StatelessWidget {
  const _MediaGridTile({
    required this.controller,
    required this.item,
    required this.onTap,
  });

  final PhotoPickerController controller;
  final MediaGridItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFE3E3E3)),
                child: item.isImage
                    ? _MediaPreview(controller: controller, item: item)
                    : _FilePreview(item: item),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: ValueListenableBuilder<int>(
                  valueListenable: controller.selectionVersion,
                  builder: (context, value, child) => _SelectionBadge(
                    selectionIndex: controller.selectionIndexFor(item.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.controller, required this.item});

  final PhotoPickerController controller;
  final MediaGridItem item;

  @override
  Widget build(BuildContext context) {
    if (item.asset != null) {
      return _AssetPreview(
        thumbnailFuture: controller.thumbnailFutureFor(item.asset!),
      );
    }

    return Image.file(
      File(item.path!),
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 34,
          color: Color(0xFF919191),
        ),
      ),
    );
  }
}

class _AssetPreview extends StatelessWidget {
  const _AssetPreview({required this.thumbnailFuture});

  final Future<Uint8List?> thumbnailFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 34,
            color: Color(0xFF919191),
          ),
        );
      },
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.item});

  final MediaGridItem item;

  @override
  Widget build(BuildContext context) {
    final extension = item.extension?.toUpperCase() ?? 'FILE';

    return Container(
      color: const Color(0xFFEDEDED),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_drive_file_rounded,
            size: 44,
            color: Color(0xFF8E8E8E),
          ),
          const SizedBox(height: 10),
          Text(
            extension,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.selectionIndex});

  final int? selectionIndex;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectionIndex != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2F6BFF) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF2F6BFF) : Colors.white,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Text(
              '$selectionIndex',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class MediaGridItem {
  const MediaGridItem._({
    required this.id,
    this.asset,
    this.path,
    this.extension,
    required this.isImage,
  });

  factory MediaGridItem.asset(AssetEntity asset) {
    return MediaGridItem._(
      id: 'asset:${asset.id}',
      asset: asset,
      extension: asset.title,
      isImage: true,
    );
  }

  factory MediaGridItem.file({required String path, required bool isImage}) {
    final extension = path.split('.').length > 1 ? path.split('.').last : null;
    return MediaGridItem._(
      id: 'file:$path',
      path: path,
      extension: extension,
      isImage: isImage,
    );
  }

  final String id;
  final AssetEntity? asset;
  final String? path;
  final String? extension;
  final bool isImage;
}

class PhotoPickerController extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();
  final LinkedHashMap<String, MediaGridItem> _selectedItems = LinkedHashMap();
  final ValueNotifier<int> selectionVersion = ValueNotifier<int>(0);
  final Map<String, int> _selectedOrder = <String, int>{};
  final Map<String, Future<Uint8List?>> _thumbnailFutures =
      <String, Future<Uint8List?>>{};

  List<AssetEntity> _devicePhotos = const [];
  List<MediaGridItem> _importedItems = const [];
  bool _isLoading = true;
  bool _hasGalleryAccess = false;

  bool get isLoading => _isLoading;
  bool get hasGalleryAccess => _hasGalleryAccess;

  List<MediaGridItem> get gridItems => [
    ..._importedItems,
    ..._devicePhotos.map(MediaGridItem.asset),
  ];

  Future<Uint8List?> thumbnailFutureFor(AssetEntity asset) {
    return _thumbnailFutures.putIfAbsent(
      asset.id,
      () => asset.thumbnailDataWithSize(const ThumbnailSize(700, 700)),
    );
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final permissionState = await PhotoManager.requestPermissionExtend();
    _hasGalleryAccess =
        permissionState == PermissionState.authorized ||
        permissionState == PermissionState.limited;

    if (_hasGalleryAccess) {
      await _loadDevicePhotos();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    if (!_hasGalleryAccess) {
      await initialize();
      return;
    }

    await _loadDevicePhotos();
    notifyListeners();
  }

  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  Future<void> pickFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (image == null) {
      return;
    }

    _prependImportedFile(image.path);
  }

  Future<void> pickFromGallery() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 100,
    );
    if (images.isEmpty) {
      return;
    }

    for (final image in images.reversed) {
      _prependImportedFile(image.path);
    }
  }

  Future<void> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    final String? path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    _prependImportedFile(path);
  }

  void toggleSelection(MediaGridItem item) {
    if (_selectedItems.containsKey(item.id)) {
      _selectedItems.remove(item.id);
    } else {
      _selectedItems[item.id] = item;
    }
    _updateSelectedOrder();
  }

  int? selectionIndexFor(String id) {
    return _selectedOrder[id];
  }

  Future<void> _loadDevicePhotos() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      _devicePhotos = const [];
      return;
    }

    _devicePhotos = await albums.first.getAssetListPaged(page: 0, size: 150);
    _syncThumbnailCache();
  }

  void _prependImportedFile(String path) {
    final item = MediaGridItem.file(path: path, isImage: _isImagePath(path));

    final updatedItems = _importedItems
        .where((element) => element.id != item.id)
        .toList(growable: true);
    updatedItems.insert(0, item);
    _importedItems = updatedItems;
    _selectedItems[item.id] = item;
    _updateSelectedOrder();
    notifyListeners();
  }

  @override
  void dispose() {
    selectionVersion.dispose();
    super.dispose();
  }

  bool _isImagePath(String path) {
    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'heic',
      'heif',
      'bmp',
    };

    final extension = path.contains('.')
        ? path.split('.').last.toLowerCase()
        : '';
    return imageExtensions.contains(extension);
  }

  void _updateSelectedOrder() {
    _selectedOrder
      ..clear()
      ..addEntries(
        _selectedItems.keys
            .toList(growable: false)
            .asMap()
            .entries
            .map((entry) => MapEntry(entry.value, entry.key + 1)),
      );
    selectionVersion.value = selectionVersion.value + 1;
  }

  void _syncThumbnailCache() {
    final visibleIds = _devicePhotos.map((asset) => asset.id).toSet();
    _thumbnailFutures.removeWhere((id, _) => !visibleIds.contains(id));
  }
}
