
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pickle
import math
import os
import meta
from tqdm import tqdm
from scipy.misc import imread
import tensorflow as tf



##########################
#                        #
#         KAGGLE         #
#  CDISCOUNT  CHALLENGE  #
#  IMAGE CLASSIFICATION  #
#                        #
##########################

# Cf. https://medium.com/@tifa2up/image-classification-using-deep-neural-networks-a-beginner-friendly-approach-using-tensorflow-94b0a090ccd4


data_dir = "C:/Users/mbriens/Documents/Kaggle/Projet_CIFAR10ImageClassif/data/cifar-10-batches-py/"
files = os.listdir(data_dir)
files.remove('batches.meta')
files.remove('readme.html')
files.remove('test_batch')

def unpickle(file):
    with open(file, 'rb') as fo:
        dict = pickle.load(fo, encoding='bytes')
    return dict

def dict_to_df(files):
    labels = []
    imgs = []
    imgsN = []
    filenames = []
    with tqdm(total=50000) as pbar:
        for file in files:
            path = os.path.join(data_dir, file)
            #print(path)
            d = unpickle(path)
            #print(d.keys())
            for line in range(len(d[b'labels'])):
                labels.append(d[b'labels'][line])
                filenames.append(d[b'filenames'][line])
                data = d[b'data'][line]
                R = data[0:1024].reshape(32,32)
                G = data[1024:2048].reshape(32,32)
                B = data[2048:3072].reshape(32,32)
                img = np.dstack((R,G,B))
                imgN = R*(1/3) + G*(1/3) + B*(1/3)
                #plt.imshow(img)
                #plt.show()
                imgs.append(img.flatten())
                imgsN.append(imgN.flatten())
                pbar.update()
    df = pd.DataFrame({'labels': labels,
                       'filenames': filenames,
                       'images_rgb': imgs,
                       'images_n': imgsN})
    return df

df = dict_to_df(files)


def image_var(df, i, prob = 1, RGB = True, flatten = True):
    if RGB:
        img = df['images_rgb'][i]
        num_channels = 3
    else:
        img = df['images_n'][i]
        num_channels = 1
    img_size = 32
    if flatten:
        img = img.reshape(img_size, img_size, num_channels)
    imgs = []
    if prob < 1:
        if np.random.rand() < prob:
            nb = 1
        else:
            nb = 0
    else:
        nb = prob
    for i in range(nb):
        # Randomly crop the input image
        image = tf.random_crop(img, size=[img_size, img_size, num_channels])
        # Randomly flip the image horizontally
        image = tf.image.random_flip_left_right(image)
        # Randomly adjust hue, contrast and saturation
        image = tf.image.random_hue(image, max_delta=0.05)
        image = tf.image.random_contrast(image, lower=0.3, upper=1.0)
        image = tf.image.random_brightness(image, max_delta=0.2)
        image = tf.image.random_saturation(image, lower=0.0, upper=2.0)
        image_new = image.eval(session= tf.InteractiveSession())
        #plt.imshow(image_new)
        #plt.show()
        imgs.append(image_new.flatten())
    return imgs



new_imgs = []
labels = []
filenames = []
with tqdm(total=len(df[0:10])) as pbar:
    for i in range(len(df[0:10])):
        gen_imgs = image_var(df, i = i, prob = 3, RGB = True, flatten = True)
        img = df['images_rgb'][i]
        nb_gen = len(gen_imgs)
        labels.extend(np.repeat(df['labels'][i], nb_gen+1))
        filenames.extend(np.repeat(df['filenames'][i], nb_gen+1))
        new_imgs.append(img)
        new_imgs.extend(gen_imgs)
        pbar.update()

new_df = pd.DataFrame({'labels': labels,
                       'filenames': filenames,
                       'images': new_imgs})


lev_labels = df['labels'].unique()
for lev in lev_labels:
    new_df[new_df['labels'] == int(lev)]



train_batch_size = 64
def random_batch():
    # Number of images in the training-set.
    num_images = len(images_train)

    # Create a random index.
    idx = np.random.choice(num_images,
                           size=train_batch_size,
                           replace=False)

    # Use the random index to select random images and labels.
    x_batch = images_train[idx, :, :, :]
    y_batch = labels_train[idx, :]

    return x_batch, y_batch












