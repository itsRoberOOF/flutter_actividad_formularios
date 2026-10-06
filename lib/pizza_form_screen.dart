import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pizza.dart';

/// Pantalla única con el formulario refactorizado (Form + GlobalKey +
/// TextFormField) y el menú de pizzas guardadas en memoria.
class PizzaFormScreen extends StatefulWidget {
  const PizzaFormScreen({super.key});

  @override
  State<PizzaFormScreen> createState() => _PizzaFormScreenState();
}

class _PizzaFormScreenState extends State<PizzaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _scroll = ScrollController();

  final _pizzas = <Pizza>[];
  Pizza? _editing;
  int _nextId = 1;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static double? _parsePrice(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null;

  String? _validatePrice(String? value) {
    final price = _parsePrice(value);
    if (price == null) return 'Ingresa un precio válido';
    if (price <= 0) return 'El precio debe ser mayor que 0';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isNew = _editing == null;
    final pizza = Pizza(
      id: _editing?.id ?? _nextId++,
      pizzaName: _name.text.trim(),
      description: _description.text.trim(),
      price: _parsePrice(_price.text)!,
    );

    setState(() {
      if (isNew) {
        _pizzas.insert(0, pizza);
      } else {
        final index = _pizzas.indexWhere((p) => p.id == pizza.id);
        _pizzas[index] = pizza;
      }
      _editing = null;
    });
    _clearForm();
    FocusScope.of(context).unfocus();

    _showMessage(
      isNew
          ? 'Pizza "${pizza.pizzaName}" agregada al menú'
          : 'Pizza "${pizza.pizzaName}" actualizada',
      Icons.check_circle_outline,
    );
  }

  void _clearForm() {
    _name.clear();
    _description.clear();
    _price.clear();
    // Limpia también los mensajes de error y el estado de interacción.
    _formKey.currentState?.reset();
  }

  void _startEdit(Pizza pizza) {
    setState(() => _editing = pizza);
    _name.text = pizza.pizzaName;
    _description.text = pizza.description;
    _price.text = pizza.price.toStringAsFixed(2);
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _clearForm();
  }

  void _delete(Pizza pizza) {
    final wasEditing = _editing?.id == pizza.id;
    setState(() {
      _pizzas.removeWhere((p) => p.id == pizza.id);
      if (wasEditing) _editing = null;
    });
    if (wasEditing) _clearForm();
    _showMessage('Pizza "${pizza.pizzaName}" eliminada', Icons.delete_outline);
  }

  void _showMessage(String text, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: colors.onInverseSurface),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_pizza),
            SizedBox(width: 12),
            Text('Pizzería'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(isEditing: isEditing),
                  const SizedBox(height: 16),
                  _buildFormCard(context, isEditing),
                  const SizedBox(height: 16),
                  _PreviewCard(
                    name: _name,
                    description: _description,
                    price: _price,
                    parsePrice: _parsePrice,
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(
                    icon: Icons.menu_book_outlined,
                    title: 'Menú',
                    trailing: _CountBadge(count: _pizzas.length),
                  ),
                  const SizedBox(height: 12),
                  if (_pizzas.isEmpty)
                    const _EmptyMenu()
                  else
                    for (final pizza in _pizzas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PizzaTile(
                          pizza: pizza,
                          selected: _editing?.id == pizza.id,
                          onTap: () => _startEdit(pizza),
                          onDelete: () => _delete(pizza),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isEditing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle(
                icon: Icons.edit_note,
                title: 'Datos de la pizza',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Margarita',
                  prefixIcon: Icon(Icons.local_pizza_outlined),
                ),
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej. Tomate, mozzarella y albahaca',
                  prefixIcon: Icon(Icons.restaurant_menu_outlined),
                ),
                maxLength: 120,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.sell_outlined),
                  prefixText: '\$ ',
                  suffixText: 'USD',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textInputAction: TextInputAction.done,
                validator: _validatePrice,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isEditing ? _cancelEdit : _clearForm,
                      icon: Icon(isEditing ? Icons.close : Icons.restart_alt),
                      label: Text(isEditing ? 'Cancelar' : 'Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(
                        isEditing ? Icons.save_as_outlined : Icons.save_outlined,
                      ),
                      label: Text(isEditing ? 'Actualizar' : 'Guardar'),
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

class _Header extends StatelessWidget {
  const _Header({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.tertiary],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add_circle_outline,
              size: 32,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar pizza' : 'Nueva pizza',
                  style: text.headlineSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Modifica los datos y presiona Actualizar.'
                      : 'Completa los datos para agregarla al menú.',
                  style: text.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count == 1 ? '1 pizza' : '$count pizzas',
        style: TextStyle(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Muestra en vivo cómo quedará la pizza mientras se llena el formulario.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.name,
    required this.description,
    required this.price,
    required this.parsePrice,
  });

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController price;
  final double? Function(String?) parsePrice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([name, description, price]),
      builder: (context, _) {
        final hasName = name.text.trim().isNotEmpty;
        final hasDescription = description.text.trim().isNotEmpty;
        final value = parsePrice(price.text);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 18, color: colors.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Vista previa',
                    style: text.labelLarge
                        ?.copyWith(color: colors.onSecondaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primary,
                    child: Icon(Icons.local_pizza,
                        size: 28, color: colors.onPrimary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasName ? name.text.trim() : 'Nombre de la pizza',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasName ? null : colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasDescription
                              ? description.text.trim()
                              : 'Sin descripción',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PriceChip(price: value != null && value > 0 ? value : null),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.price});

  final double? price;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: price == null ? colors.surfaceContainerHighest : colors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        price == null ? '\$ --' : '\$${price!.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: price == null ? colors.onSurfaceVariant : colors.onPrimary,
        ),
      ),
    );
  }
}

class _PizzaTile extends StatelessWidget {
  const _PizzaTile({
    required this.pizza,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final Pizza pizza;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? colors.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor:
              selected ? colors.primary : colors.tertiaryContainer,
          child: Icon(
            selected ? Icons.edit : Icons.local_pizza_outlined,
            color: selected ? colors.onPrimary : colors.onTertiaryContainer,
          ),
        ),
        title: Text(
          pizza.pizzaName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          pizza.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PriceChip(price: pizza.price),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: colors.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.no_food_outlined, size: 48, color: colors.outline),
          const SizedBox(height: 12),
          Text('Aún no hay pizzas en el menú', style: text.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Las pizzas que guardes aparecerán aquí. Tócalas para editarlas.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
