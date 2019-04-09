---
layout: post
comments: true
author: Manuel Capel
title: Transforming Keras Model into Tensorflow Estimator
date: 2019-04-01
categories: [deep learning,Tensorflow]
---
A [Tensorflow `Estimator`](https://www.tensorflow.org/api_docs/python/tf/estimator/Estimator) is a convenient object to manage models, especially for production. And [Keras](https://keras.io/) is a convenient library to build models. Thus combining both is a powerful way to leverage their strenghts. Especially since Keras will be the [standard](https://medium.com/tensorflow/standardizing-on-keras-guidance-on-high-level-apis-in-tensorflow-2-0-bad2b04c819a) for building models in Tensorflow 2.0 Let see how it works:

## Building a Keras model
Here we will build a simple Keras model for the famous [MNIST data](https://en.wikipedia.org/wiki/MNIST_database):
### Importing and preparing the data
```python
# Define some constants first
img_rows, img_cols = 28, 28
input_shape = (img_rows, img_cols, 1)
num_classes = 10

# Import data
((train_data, train_labels), (eval_data, eval_labels)) = tf.keras.datasets.mnist.load_data()

# Format data
# convert class vectors to binary class matrices
train_labels = tf.keras.utils.to_categorical(train_labels, num_classes)
eval_labels = tf.keras.utils.to_categorical(eval_labels, num_classes)

train_data = train_data / np.float32(255.0)
eval_data = eval_data /np.float32(255.0)

train_data = train_data.reshape(train_data.shape[0], img_rows, img_cols, 1)
eval_data = eval_data.reshape(eval_data.shape[0], img_rows, img_cols, 1)

```

### Defining the model 
We define a simple model with 2 convolutional layers followed by a pooling layer, a dense layer and a final softmax layer providing the class probabilities (with some dropout for regularization):
```python
model_cnn_0 = tf.keras.models.Sequential()
model_cnn_0.add(tf.keras.layers.Conv2D(32, kernel_size=(3, 3),
                 activation='relu',
                 input_shape=input_shape,
                 name='x'
                ))
model_cnn_0.add(tf.keras.layers.Conv2D(64, (3, 3), activation='relu'))
model_cnn_0.add(tf.keras.layers.MaxPooling2D(pool_size=(2, 2)))
model_cnn_0.add(tf.keras.layers.Dropout(0.25))
model_cnn_0.add(tf.keras.layers.Flatten())
model_cnn_0.add(tf.keras.layers.Dense(128, activation='relu'))
model_cnn_0.add(tf.keras.layers.Dropout(0.5))
model_cnn_0.add(tf.keras.layers.Dense(num_classes, activation='softmax'))
```
The we simply compile the model:
```python
model_cnn_0.compile(loss=tf.keras.losses.categorical_crossentropy,
                    optimizer=tf.keras.optimizers.Adadelta(),
                    metrics=['accuracy'])
```

## Building and using an `Estimator`
There is a simple ingredient to transform a Keras model to a Tensorflow `Estimator`, this is the method `model_to_estimator` from [tensorflow.keras.estimator](https://www.tensorflow.org/api_docs/python/tf/keras/estimator/) that takes the model we just built as argument:

```python
est_cnn_0 = tf.keras.estimator.model_to_estimator(keras_model=model_cnn_0)
```
Remark: Per default, the estimator will be save in a sub-directory of `/tmp` created automatically. If you want to define another directory, use the argument `model_dir`.
### Training a model through an `Estimator`
For training a Keras model through the Tensorflow `Estimator` encapsulating it, we first have to define a training input function. This function feeds the model with data during its training:
```python
train_input_fn = tf.estimator.inputs.numpy_input_fn(
    x={'x_input': train_data},  # 'x_input' because name of 1st layer is 'x', `model_cnn_0.input_names`
    y=train_labels,
    batch_size=100,
    num_epochs=None,
    shuffle=True)
```
On line 2, `train_data` is built in the first step, as well as well as `train_labels` on line 3.

Remarks:
* In the second step where we defined the model, we called the for layer `x`. Thus the `Estimator` expects the key `x_input` for the dictionary given to the parameter `x` of the input function (see line 2). You can see what input name(s) are expected with `model.input_names`
* `num_epochs` is set to `None` because the number of epochs for the training will be set in the next train step.
* There is no rule, resp. plenty of such, for setting `batch_size`. Put here what fits you best.

And then we train the model:
```python
est_cnn_0.train(input_fn=train_input_fn, steps=2000)
```
The number of epochs for the training is set here through the parameter `steps`.We give also as argument the data input function `train_input_fn` we defined on the previous step.

### Computing estimations with an `Estimator`
Once the estimator is trained, we can compute estimations for incoming MNIST images (that have not been seen during the training):

As for training, we define an input function for the estimations:
```python
eval_input_fn = tf.estimator.inputs.numpy_input_fn(
    x={'x_input': eval_data},
    y=eval_labels,
    num_epochs=1,
    shuffle=False)
```
Remarks:
* Setting the parameter `shuffle` to `True` helps for training the model, but is useless to compute estimations
* Only one epoch is needed for evaluations
 
The we can for example evaluate our `Estimator` on the evaluation data:
```python
eval_results = est_cnn_0.evaluate(input_fn=eval_input_fn)
print(eval_results)
```

And that's it :)



## Shortcoming
The main shortcoming I see with this approach is the impossibility to use [Keras callbacks](https://keras.io/callbacks/) by training the `Estimator`. And it can be very convenient to have for example [early stopping](https://keras.io/callbacks/#earlystopping) or a [learning rate scheduler](https://keras.io/callbacks/#learningratescheduler) while training a Keras model.

The only way I see to circumvent it is to train beforehand the Keras model, persist it and transform this model into an `Estimator` *after* it's trained.

For this, we first define and compile the model as before. Then we define 2 callbacks:
1. A callback that will stop the training after 3 epochs without improvement of the accuracy on the validation data:
```python
early_stopping_callback = tf.keras.callbacks.EarlyStopping(monitor='val_acc', patience=3)
```
2. A callback that will persist (in `'best_model.h5'`) the best model according to the accuracy on the validation data:
```python
model_checkpoint_callback = tf.keras.callbacks.ModelCheckpoint('best_model.h5', monitor='val_acc')
```

Then we train the model with those callbacks:
```python
model_cnn_0.fit(train_data, train_labels, validation_data=(eval_data, eval_labels), 
          epochs=2000, 
          callbacks=[early_stopping_callback, model_checkpoint_callback])
```

And the trick is to transform it now, *after it's trained*, into an `Estimator`:
```python
est_cnn_0_trained = tf.keras.estimator.model_to_estimator(keras_model_path='best_model.h5')
```
The model is directly loaded from the path where it has been persisted. This allows the model and the `Estimator` to have separated live: you can re-train, update etc. the model, persist it and then re-transform it into an `Estimator`.

After that, we can evaluate this `Estimator` again with the evaluation data:

```python
eval_results = est_cnn_0_trained.evaluate(input_fn=eval_input_fn)
```
(Btw, thanks to the callbacks, the accuracy is a bit better than previously)

We can also use the `estimator`to make predictions (also on the evaluation data, for sake of simplicity):

```python
predict_input_fn = tf.estimator.inputs.numpy_input_fn(
    x={'x_input': eval_data},
    y=None,
    num_epochs=1,
    shuffle=False)

predictions = est_cnn_0_trained.predict(input_fn=predict_input_fn)
predictions = np.array([list(p.values())[0] for p in list(predictions)])
```

Remarks:
* The input function used for predictions does not need any value for `y` (obviously, since its  what we want to predict), thus it is set to `None`
* The result coming from the `predict` method needs some transformations before being useable as a numpy array, shown at line 8 above.

## Conclusion
Hope this can help to make deep learning models production-ready. You can also check the [notebook](https://github.com/mancap314/miscellanous/blob/master/cnn_estimator.ipynb) where those methods are implemented. And if you have questions, just ask.
