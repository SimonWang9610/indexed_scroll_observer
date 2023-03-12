import 'package:flutter/material.dart';

class SliverJumpWidget extends StatefulWidget {
  final String label;
  final bool force;
  final ValueChanged<int> onJump;
  const SliverJumpWidget({
    super.key,
    required this.label,
    required this.onJump,
    this.force = false,
  });

  @override
  State<SliverJumpWidget> createState() => _SliverJumpWidgetState();
}

class _SliverJumpWidgetState extends State<SliverJumpWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          height: 30,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: "Jump on ${widget.label}",
              suffixIcon: IconButton(
                onPressed: () {
                  final index = int.tryParse(_controller.text);

                  if (index != null || widget.force) {
                    widget.onJump(index ?? 0);
                  }
                },
                icon: const Icon(Icons.fast_forward_rounded),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
