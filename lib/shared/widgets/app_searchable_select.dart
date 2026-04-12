import 'package:flutter/material.dart';

class AppSearchableSelectOption<T> {
  const AppSearchableSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.searchTerms = const <String>[],
  });

  final T value;
  final String label;
  final String? subtitle;
  final List<String> searchTerms;
}

class AppSearchableSelectField<T> extends StatelessWidget {
  const AppSearchableSelectField({
    super.key,
    required this.label,
    required this.searchHint,
    required this.options,
    this.value,
    this.placeholder = 'Select an option',
    this.prefixIcon = Icons.arrow_drop_down_circle_outlined,
    this.onChanged,
    this.enabled = true,
    this.isLoading = false,
    this.helperText,
    this.clearLabel,
  });

  final String label;
  final String searchHint;
  final List<AppSearchableSelectOption<T>> options;
  final T? value;
  final String placeholder;
  final IconData prefixIcon;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool isLoading;
  final String? helperText;
  final String? clearLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    AppSearchableSelectOption<T>? selectedOption;
    for (final option in options) {
      if (option.value == value) {
        selectedOption = option;
        break;
      }
    }
    final canOpen = enabled && !isLoading && onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: !canOpen
                ? null
                : () async {
                    final result =
                        await showModalBottomSheet<_SelectSheetResult<T>>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _AppSearchableSelectSheet<T>(
                            title: label,
                            searchHint: searchHint,
                            options: options,
                            selectedValue: value,
                            clearLabel: clearLabel,
                          ),
                        );
                    if (result == null) {
                      return;
                    }
                    onChanged?.call(result.value);
                  },
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                color: canOpen
                    ? Colors.white.withValues(alpha: 0.96)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            prefixIcon,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedOption?.label ?? placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selectedOption == null
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (selectedOption?.subtitle case final subtitle?) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if ((helperText ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AppSearchableSelectSheet<T> extends StatefulWidget {
  const _AppSearchableSelectSheet({
    required this.title,
    required this.searchHint,
    required this.options,
    required this.selectedValue,
    this.clearLabel,
  });

  final String title;
  final String searchHint;
  final List<AppSearchableSelectOption<T>> options;
  final T? selectedValue;
  final String? clearLabel;

  @override
  State<_AppSearchableSelectSheet<T>> createState() =>
      _AppSearchableSelectSheetState<T>();
}

class _AppSearchableSelectSheetState<T>
    extends State<_AppSearchableSelectSheet<T>> {
  late final TextEditingController searchController;
  String query = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final normalizedQuery = query.trim().toLowerCase();
    final filteredOptions = widget.options
        .where((option) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          final haystack = <String>[
            option.label,
            option.subtitle ?? '',
            ...option.searchTerms,
          ].join(' ').toLowerCase();
          return haystack.contains(normalizedQuery);
        })
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      query = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                query = '';
                              });
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: filteredOptions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            'No matches found.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount:
                              filteredOptions.length +
                              (widget.clearLabel == null ? 0 : 1),
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, thickness: 0.7),
                          itemBuilder: (context, index) {
                            if (widget.clearLabel != null && index == 0) {
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                leading: const Icon(
                                  Icons.filter_alt_off_rounded,
                                ),
                                title: Text(widget.clearLabel!),
                                onTap: () => Navigator.of(
                                  context,
                                ).pop(_SelectSheetResult<T>(value: null)),
                              );
                            }

                            final option =
                                filteredOptions[index -
                                    (widget.clearLabel == null ? 0 : 1)];
                            final isSelected =
                                option.value == widget.selectedValue;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_SelectSheetResult<T>(value: option.value)),
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                option.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: option.subtitle == null
                                  ? null
                                  : Text(option.subtitle!),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectSheetResult<T> {
  const _SelectSheetResult({required this.value});

  final T? value;
}
