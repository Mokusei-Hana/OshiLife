import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `TicketEntryView.swift` as a modal bottom sheet: name, price
/// (whole yen), description; add requires a non-blank name.
class TicketEntrySheet extends StatefulWidget {
  const TicketEntrySheet({super.key, required this.onAdd});

  final void Function(String name, int? price, String? description) onAdd;

  @override
  State<TicketEntrySheet> createState() => _TicketEntrySheetState();
}

class _TicketEntrySheetState extends State<TicketEntrySheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canAdd => _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ticketAdd,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton(
                onPressed: _canAdd
                    ? () {
                        final price = int.tryParse(_price.text.trim());
                        widget.onAdd(
                          _name.text,
                          price,
                          _description.text.isEmpty ? null : _description.text,
                        );
                        Navigator.of(context).pop();
                      }
                    : null,
                child: Text(l10n.commonDone),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.fieldTicketName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.fieldTicketPrice,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              labelText: l10n.fieldTicketDescription,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
