# Semana 7 - Refactor de formulario legacy

## Equipo e Integrantes

- **Equipo:** #11
- Roberto Morán
- Óscar Pleités
- Diego Arévalo
- Roberto Polanco
- Christopher Marroquín
- Angie Guzmán

## Formulario actual

El formulario utilizado como base para la actividad proviene del libro **Flutter Cookbook** (3.ª edición), capítulo 9. Su código se encuentra en el siguiente repositorio:

- **Repositorio:** [PacktPublishing/Flutter-Cookbook-Third-Edition](https://github.com/PacktPublishing/Flutter-Cookbook-Third-Edition/tree/main)
- **Archivo:** [`Chapter09/lib/pizza_list_screen.dart`](https://github.com/PacktPublishing/Flutter-Cookbook-Third-Edition/blob/main/Chapter09/lib/pizza_list_screen.dart)
- **Método:** `_showPizzaDialog`
- **Líneas:** 132-192

Principalmente, destaca el hecho de que el formulario utiliza `TextField`, lo que complica el manejo de validaciones, ya que este widget no se integra con un `Form` ni cuenta con una propiedad `validator`. Además, no hay ningún uso de `Form` ni de `TextFormField`:

```dart
Future<void> _showPizzaDialog([Pizza? pizza]) async {
  final nameController = TextEditingController(text: pizza?.pizzaName ?? '');
  final descController = TextEditingController(
    text: pizza?.description ?? '',
  );
  final priceController = TextEditingController(
    text: pizza?.price.toString() ?? '',
  );

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(pizza == null ? 'Add Pizza' : 'Edit Pizza'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            String result;
            final newPizza = Pizza(
              id: pizza?.id ?? 0,
              pizzaName: nameController.text,
              description: descController.text,
              price: double.tryParse(priceController.text) ?? 0,
            );

            if (pizza == null) {
              result = await helper.postPizza(newPizza);
            } else {
              result = await helper.putPizza(newPizza);
            }
            debugPrint(result);
            Navigator.pop(context);
            if (!mounted) return;
            setState(() {});
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
```

## Problemas

| #   | Problema                                                                   | Dónde    | Consecuencia                                              |
| --- | -------------------------------------------------------------------------- | -------- | --------------------------------------------------------- |
| 1   | Los tres `TextEditingController` nunca se liberan con `dispose()`.         | L133-139 | Fuga de memoria cada vez que se abre el diálogo.          |
| 2   | El formulario no realiza ninguna validación.                               | L148-159 | Se pueden guardar pizzas con nombre o descripción vacíos. |
| 3   | El precio se convierte con `double.tryParse(...) ?? 0`.                    | L174     | Un precio inválido se guarda como `0` sin avisar.         |
| 4   | El campo de precio no define `keyboardType` numérico ni `inputFormatters`. | L156     | Se muestra el teclado de texto y se aceptan letras.       |
| 5   | Los campos no definen `textInputAction`.                                   | L148-159 | La navegación entre campos es poco fluida.                |

## Dónde se puede aplicar Form, FormField y GlobalKey

| Elemento                                        | Dónde se aplica                                                                                   | Qué resuelve                                                                                               |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **`StatefulWidget` propio** (`PizzaFormScreen`) | Se extrae el formulario del `AlertDialog` a su propio widget, que funciona como pantalla inicial. | Los controladores pasan al `State` y se liberan en `dispose()` (problema 1).                               |
| **`GlobalKey<FormState>`**                      | Campo `_formKey` asignado a `Form(key: _formKey)`.                                                | Permite llamar a `_formKey.currentState!.validate()` al pulsar _Guardar_.                                  |
| **`Form`**                                      | Envuelve la `Column` con los campos (antes la del `AlertDialog`, en L145).                        | Agrupa los campos para validarlos juntos (problemas 2 y 3).                                                |
| **`TextFormField`**                             | Reemplaza los tres `TextField` (L148, L152 y L156).                                               | Cada campo recibe un `validator`: nombre y descripción obligatorios, precio mayor que 0 (problemas 2 y 3). |
| **`validator` / `validate()`**                  | Método `_submit()`, asociado al botón _Guardar_ (antes el `onPressed` de _Save_).                 | Si hay errores no se guarda la pizza y se muestran los mensajes.                                           |
| **`keyboardType` + `inputFormatters`**          | `TextFormField` del precio.                                                                       | Teclado decimal y solo dígitos y separador decimal (problema 4).                                           |
| **`textInputAction` + `onFieldSubmitted`**      | Todos los `TextFormField`.                                                                        | _Siguiente_ entre campos y _Listo_ en el último, que envía el formulario (problema 5).                     |

## Form refactorizado

El formulario refactorizado se encuentra en el archivo `lib/pizza_form_screen.dart`, dentro del widget `PizzaFormScreen`, que se muestra como pantalla inicial de la app en lugar del `AlertDialog` original. Su `State` contiene el `_formKey`, los tres `TextEditingController` (liberados en `dispose()`) y los métodos `_required`, `_validatePrice`, `_parsePrice` y `_submit()`, mientras que los `TextFormField` se definen en el método `_buildFormCard`. El modelo `Pizza` se encuentra en `lib/pizza.dart`, y el estilo de los campos (bordes, relleno y color de los iconos) se configura en el `InputDecorationTheme` de `lib/main.dart`. Como el proyecto no incluye el `HttpHelper` del libro, las pizzas guardadas se mantienen en una lista en memoria en lugar de enviarse con `postPizza` o `putPizza`.

### Resumen de cambios

| Antes                                 | Después                                                                  |
| ------------------------------------- | ------------------------------------------------------------------------ |
| Controladores locales sin `dispose()` | Controladores en el `State`, liberados en `dispose()`                    |
| `TextField` sin validación            | `TextFormField` con `validator` dentro de un `Form`                      |
| Precio inválido se guarda como `0`    | El precio debe ser un número mayor que 0 o no se envía                   |
| Teclado de texto para el precio       | Teclado decimal y solo caracteres numéricos                              |
| Sin `textInputAction` en los campos   | _Siguiente_ entre campos y _Listo_ en el último, que envía el formulario |

## Uso de IA

Durante la actividad se utilizó inteligencia artificial como herramienta de apoyo en tres aspectos. Primero, para diagnosticar los problemas del formulario original y proponer posibles mejoras, como el uso de `Form`, `TextFormField` y `GlobalKey`, las validaciones y la configuración de los campos. Segundo, para estilizar la app, agregando iconos, decoraciones y un tema visual que evitan que el formulario se vea vacío. Por último, como apoyo en la redacción de este README. En todos los casos, el resultado fue revisado y ajustado por el equipo.
