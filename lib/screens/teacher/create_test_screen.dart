import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';

class CreateTestScreen extends ConsumerStatefulWidget {
  /// If provided, the screen acts as an editor for an existing test.
  final String? existingTestId;
  final String? existingTestName;
  final int? existingDuration;
  final List<Map<String, dynamic>>? existingQuestions;

  const CreateTestScreen({
    super.key,
    this.existingTestId,
    this.existingTestName,
    this.existingDuration,
    this.existingQuestions,
    this.existingHasNegativeMarking = false,
  });
  final bool existingHasNegativeMarking;

  bool get isEditing => existingTestId != null;

  @override
  ConsumerState<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends ConsumerState<CreateTestScreen> {
  final List<Map<String, dynamic>> _questions = [];
  final _testNameController = TextEditingController();
  int _selectedDuration = 10;
  bool _hasNegativeMarking = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    if (widget.isEditing) {
      _testNameController.text = widget.existingTestName ?? '';
      _selectedDuration = widget.existingDuration ?? 10;
      _hasNegativeMarking = widget.existingHasNegativeMarking;
      if (widget.existingQuestions != null) {
        _questions.addAll(widget.existingQuestions!);
      }
    }
  }

  void _addManualQuestion() {
    showDialog(
      context: context,
      builder: (context) => const _ManualQuestionDialog(),
    ).then((newQuestion) {
      if (newQuestion != null) {
        setState(() => _questions.add(newQuestion));
      }
    });
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => _ManualQuestionDialog(
        existingQuestion: _questions[index],
      ),
    ).then((editedQuestion) {
      if (editedQuestion != null) {
        setState(() => _questions[index] = editedQuestion);
      }
    });
  }

  void _reorderQuestion(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }

  void _generateWithAI() {
    showDialog(
      context: context,
      builder: (context) => const _AIGenerationDialog(),
    ).then((generatedQuestions) {
      if (generatedQuestions != null) {
        setState(() => _questions.addAll(generatedQuestions));
      }
    });
  }

  bool _isPublishing = false;

  void _publishTest() async {
    if (_testNameController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter test name and add questions.'),
          backgroundColor: AppTheme.warning.withValues(alpha: 0.9),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final dbService = ref.read(databaseServiceProvider);
      
      if (widget.isEditing) {
        // Update existing test
        await dbService.updateTest(
          widget.existingTestId!,
          _testNameController.text,
          _selectedDuration,
          _questions,
          hasNegativeMarking: _hasNegativeMarking,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test updated successfully! ✅'),
              backgroundColor: AppTheme.emerald,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate update
        }
      } else {
        // Create new test
        final code = await dbService.createTest(_testNameController.text, _selectedDuration, _questions, hasNegativeMarking: _hasNegativeMarking);
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceContainer,
              title: Text('Test Published! 🎉', style: AppTheme.headlineSM),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Share this code with your students:', style: AppTheme.bodyLG),
                  const SizedBox(height: 24),
                  // Large code display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      code,
                      style: AppTheme.headlineLG.copyWith(
                        color: AppTheme.emerald,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                  },
                  child: Text('Copy Code', style: AppTheme.labelMD),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              GlassAppBar(title: widget.isEditing ? 'Edit Test' : 'Create New Test'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Test Name Input
                      GlassTextField(
                        controller: _testNameController,
                        hintText: 'Test Name (e.g. Flutter Basics)',
                        prefixIcon: Icons.edit_rounded,
                      ),
                      const SizedBox(height: 16),
                      
                      // Duration Selector
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Text('Duration', style: AppTheme.bodyLG),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                if (_selectedDuration > 5) setState(() => _selectedDuration -= 5);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.emerald),
                                ),
                                child: const Icon(Icons.remove_rounded, color: AppTheme.emerald, size: 16),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text('$_selectedDuration Minutes', style: AppTheme.labelMD),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedDuration += 5);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.emerald),
                                ),
                                child: const Icon(Icons.add_rounded, color: AppTheme.emerald, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Negative Marking Selector
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Negative Marking', style: AppTheme.bodyLG),
                                  Text('Correct: +4, Wrong: -1', style: AppTheme.bodySM.copyWith(color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _hasNegativeMarking,
                              onChanged: (val) => setState(() => _hasNegativeMarking = val),
                              activeColor: AppTheme.emerald,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              label: 'Add Manually',
                              icon: Icons.add_rounded,
                              onPressed: _addManualQuestion,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: EmeraldButton(
                              label: 'Generate AI',
                              icon: Icons.auto_awesome_rounded,
                              onPressed: _generateWithAI,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Questions List Header
                      Row(
                        children: [
                          Text('Questions (${_questions.length})', style: AppTheme.headlineSM),
                          const Spacer(),
                          if (_questions.length > 1)
                            Text('Hold & drag to reorder', style: AppTheme.labelSM),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Questions List — ReorderableListView for drag & drop
                      Expanded(
                        child: _questions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Empty state illustration
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.emerald.withValues(alpha: 0.06),
                                        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.15)),
                                      ),
                                      child: Icon(Icons.quiz_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                                    ),
                                    const SizedBox(height: 20),
                                    Text('No questions added yet', style: AppTheme.headlineSM.copyWith(color: AppTheme.textMuted)),
                                    const SizedBox(height: 8),
                                    Text('Add manually or generate with AI', style: AppTheme.bodySM),
                                  ],
                                ),
                              )
                            : ReorderableListView.builder(
                                proxyDecorator: (child, index, animation) {
                                  return Material(
                                    color: Colors.transparent,
                                    elevation: 4,
                                    shadowColor: AppTheme.emerald.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    child: child,
                                  );
                                },
                                buildDefaultDragHandles: false,
                                itemCount: _questions.length,
                                onReorder: _reorderQuestion,
                                itemBuilder: (context, index) {
                                  final q = _questions[index];
                                  return Padding(
                                    key: ValueKey('q_$index'),
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Drag Handle
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(Icons.drag_handle_rounded, color: AppTheme.textMuted, size: 20),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Q Number Badge
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.emerald.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: AppTheme.labelMD.copyWith(color: AppTheme.emerald),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Question Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  q['question'],
                                                  style: AppTheme.bodyLG.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Ans: ${q['correctAnswer']}',
                                                  style: AppTheme.bodySM.copyWith(color: AppTheme.mint),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Edit & Delete Actions
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _editQuestion(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.emerald.withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.edit_rounded, color: AppTheme.emerald, size: 16),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () => setState(() => _questions.removeAt(index)),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.error.withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      // Publish CTA
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                        child: EmeraldButton(
                          label: widget.isEditing ? 'Update Test ✅' : 'Publish Test 🚀',
                          isLoading: _isPublishing,
                          onPressed: _publishTest,
                        ),
                      ),
                    ],
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

class _ManualQuestionDialog extends StatefulWidget {
  final Map<String, dynamic>? existingQuestion;
  
  const _ManualQuestionDialog({this.existingQuestion});

  @override
  State<_ManualQuestionDialog> createState() => _ManualQuestionDialogState();
}

class _ManualQuestionDialogState extends State<_ManualQuestionDialog> {
  final _qController = TextEditingController();
  final _o1Controller = TextEditingController();
  final _o2Controller = TextEditingController();
  final _o3Controller = TextEditingController();
  final _o4Controller = TextEditingController();
  String _correctAnswer = 'Option 1';

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing an existing question
    if (widget.existingQuestion != null) {
      final q = widget.existingQuestion!;
      _qController.text = q['question'] ?? '';
      final options = q['options'] as List<dynamic>? ?? [];
      if (options.length >= 1) _o1Controller.text = options[0].toString();
      if (options.length >= 2) _o2Controller.text = options[1].toString();
      if (options.length >= 3) _o3Controller.text = options[2].toString();
      if (options.length >= 4) _o4Controller.text = options[3].toString();
      // Determine which option is correct
      final correct = q['correctAnswer'] ?? '';
      if (options.length >= 1 && correct == options[0].toString()) _correctAnswer = 'Option 1';
      else if (options.length >= 2 && correct == options[1].toString()) _correctAnswer = 'Option 2';
      else if (options.length >= 3 && correct == options[2].toString()) _correctAnswer = 'Option 3';
      else if (options.length >= 4 && correct == options[3].toString()) _correctAnswer = 'Option 4';
    }
  }

  Widget _buildForm(StateSetter? customSetState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassTextField(
          controller: _qController,
          hintText: 'Question',
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 12),
        GlassTextField(controller: _o1Controller, hintText: 'Option 1', minLines: 1, maxLines: 3, keyboardType: TextInputType.multiline),
        const SizedBox(height: 12),
        GlassTextField(controller: _o2Controller, hintText: 'Option 2', minLines: 1, maxLines: 3, keyboardType: TextInputType.multiline),
        const SizedBox(height: 12),
        GlassTextField(controller: _o3Controller, hintText: 'Option 3', minLines: 1, maxLines: 3, keyboardType: TextInputType.multiline),
        const SizedBox(height: 12),
        GlassTextField(controller: _o4Controller, hintText: 'Option 4', minLines: 1, maxLines: 3, keyboardType: TextInputType.multiline),
        const SizedBox(height: 16),
        // Custom styled dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.glassInput,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppTheme.surfaceDark,
              value: _correctAnswer,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
              isExpanded: true,
              style: AppTheme.bodyLG.copyWith(color: AppTheme.textPrimary),
              items: ['Option 1', 'Option 2', 'Option 3', 'Option 4']
                  .map((e) => DropdownMenuItem(value: e, child: Text('Correct: $e')))
                  .toList(),
              onChanged: (v) {
                setState(() => _correctAnswer = v!);
                if (customSetState != null) customSetState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingQuestion != null;
    return Dialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Edit Question' : 'Add Question', style: AppTheme.headlineSM),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: AppTheme.emerald),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => StatefulBuilder(
                            builder: (context, setFullScreenState) {
                              return Scaffold(
                                backgroundColor: AppTheme.background,
                                appBar: AppBar(
                                  backgroundColor: AppTheme.surfaceContainer,
                                  iconTheme: const IconThemeData(color: Colors.white),
                                  title: Text('Full Screen Editor', style: AppTheme.headlineSM),
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: AppTheme.emerald),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                                body: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24.0),
                                  child: _buildForm(setFullScreenState),
                                ),
                              );
                            }
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildForm(null),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: AppTheme.labelMD.copyWith(color: AppTheme.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EmeraldButton(
                      label: isEditing ? 'Save' : 'Add',
                      onPressed: () {
                        if (_qController.text.isEmpty) return;
                        Navigator.pop(context, {
                          'question': _qController.text,
                          'options': [
                            _o1Controller.text,
                            _o2Controller.text,
                            _o3Controller.text,
                            _o4Controller.text,
                          ],
                          'correctAnswer': _correctAnswer == 'Option 1' ? _o1Controller.text :
                                           _correctAnswer == 'Option 2' ? _o2Controller.text :
                                           _correctAnswer == 'Option 3' ? _o3Controller.text : _o4Controller.text,
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AIGenerationDialog extends ConsumerStatefulWidget {
  const _AIGenerationDialog();

  @override
  ConsumerState<_AIGenerationDialog> createState() => _AIGenerationDialogState();
}

class _AIGenerationDialogState extends ConsumerState<_AIGenerationDialog> {
  final _topicController = TextEditingController();
  final _countController = TextEditingController(text: '5');
  bool _isLoading = false;

  void _generate() async {
    final topic = _topicController.text.trim();
    final count = int.tryParse(_countController.text) ?? 5;
    
    if (topic.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final aiService = ref.read(aiServiceProvider);
      final questions = await aiService.generateQuestions(topic, count);
      
      if (mounted && questions != null) {
        Navigator.pop(context, questions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.emerald),
                const SizedBox(width: 8),
                Text('Generate with AI', style: AppTheme.headlineSM),
              ],
            ),
            const SizedBox(height: 24),
            GlassTextField(
              controller: _topicController,
              hintText: 'Topic (e.g. History)',
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: _countController,
              hintText: 'Number of Questions',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: AppTheme.labelMD.copyWith(color: AppTheme.textMuted)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: EmeraldButton(
                    label: 'Generate',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _generate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
