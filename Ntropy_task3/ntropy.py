"""Ntropy - Assignment task 3

"""


from multiprocessing import Pool
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import confusion_matrix, classification_report, \
    roc_auc_score
from sklearn.model_selection import train_test_split
from tensorflow.keras import layers
from tensorflow.keras.models import Model

PATH = '~/git/Projects/Ntropy_task3/'
DEBUG = False
PARALLELIZE = True
RANDOM_STATE = 25


def train_test_split_custom(df, fraud_ratio=.1):
    """Custom function to split train and test with no fraud data in the train

    :param df: DataFrame
    :param fraud_ratio: Float
    :return: tuple with 2 DataFrames for train and test
    """
    fraud = df[df['Class'] == 1]
    clean = df[df['Class'] == 0]

    test_size_clean = int(len(fraud) * 1 / fraud_ratio)
    clean_train, clean_test = train_test_split(clean,
                                               test_size=test_size_clean,
                                               random_state=RANDOM_STATE)

    # Only clean to train on (autoencoder trained on non-abnormal data)
    train = clean_train
    train = train.sample(frac=1, random_state=RANDOM_STATE)\
        .reset_index(drop=True)

    # Test with both clean and fraud
    test = pd.concat([fraud, clean_test])
    test = test.sample(frac=1, random_state=RANDOM_STATE)\
        .reset_index(drop=True)

    return train, test


# def show_graphs(df):
#     class_counts = df['Class'].value_counts()
#     ax = class_counts.plot(kind='bar')
#     for idx, value in class_counts.iteritems():
#         ax.annotate(value,
#                     (idx, value),
#                     xytext=(0, 5),
#                     horizontalalignment='center',
#                     textcoords='offset points')
#     plt.title('Fraud occurrences')
#     plt.xlabel('Fraud')
#     plt.ylabel('Frequency')
#     plt.show()
#
#     plt.hist(data['Amount'])
#     plt.title('Histogram of \'Amount\'')
#     plt.show()
#
#     plt.hist(np.log10(.1 + data['Amount']))
#     plt.title('Histogram of log(1+\'Amount\')')
#     plt.show()


def fit_autoencoder(df, latent_dim=8):
    """Define and train the autoencoder model

    :param df: DataFrame
    :param latent_dim: int
    :return: Autoencoder
    """
    df = np.asarray(df)
    input_dim = df.shape[1]

    class Autoencoder(Model):
        def __init__(self, latent_dim):
            super(Autoencoder, self).__init__()
            self.latent_dim = latent_dim
            self.encoder = tf.keras.Sequential([
                layers.Dense(input_dim, activation='tanh'),
                layers.Dense(20, activation='tanh'),
                layers.Dense(15, activation='tanh'),
                layers.Dense(latent_dim, activation='elu')
            ])
            self.decoder = tf.keras.Sequential([
                layers.Dense(20, activation='tanh'),
                layers.Dense(input_dim, activation='tanh')
            ])

        def call(self, x):
            encoded = self.encoder(x)
            decoded = self.decoder(encoded)
            return decoded

    autoencoder = Autoencoder(latent_dim)
    autoencoder.compile(optimizer='adam',
                        loss='mse')
    autoencoder.fit(df,
                    df,
                    epochs=50 if DEBUG else 250,
                    shuffle=True,
                    batch_size=256,
                    validation_split=.2 if DEBUG else .1)
    return autoencoder


def wrap_encode(train_test_tuple):
    """Encapsulates the encoding of the test set

    :param train_test_tuple: tuple with 2 DataFrames for train & test
    :return:
    """
    train, test = train_test_tuple
    scaler = StandardScaler()
    log_amount_train = np.log10(.1 + train['Amount']).values.reshape(-1, 1)
    train['normalized_Amount'] = scaler.fit_transform(log_amount_train)
    log_amount_test = np.log10(.1 + test['Amount']).values.reshape(-1, 1)
    test['normalized_Amount'] = scaler.transform(log_amount_test)

    train = train.drop(['Time', 'Amount'], axis=1)
    x_train = train.drop('Class', axis=1)

    test = test.drop(['Time', 'Amount'], axis=1)
    x_test = test.drop('Class', axis=1)

    autoencoder = fit_autoencoder(x_train)

    encoded_x_test = autoencoder.encoder(np.asarray(x_test)).numpy()

    new_encoded_test = pd.DataFrame(encoded_x_test)
    new_encoded_test['y'] = test['Class'].values
    return new_encoded_test


def parallelize_encoding(data_alice, data_bob):
    """Process & encode the data from Alice & Bob in parallel (independently)

    :param data_alice: tuple with 2 DataFrames for train & test from Alice
    :param data_bob: tuple with 2 DataFrames for train & test from Bob
    :return: DataFrame
    """
    pool = Pool(2)
    df = pd.concat(pool.map(wrap_encode, [data_alice, data_bob]))
    pool.close()
    pool.join()
    return df


def fit_rf_classifier(x, y):
    """Define and train the random forest classifier model

    :param x: DataFrame with features
    :param y: Series with target
    :return: tuple (classifier model, tuple (features test, target test))
    """
    x_train, x_test, y_train, y_test = \
        train_test_split(x, y, test_size=.25, random_state=RANDOM_STATE)

    model_rf = RandomForestClassifier(n_estimators=100,
                                      max_depth=15,
                                      min_samples_split=5,
                                      min_samples_leaf=10,
                                      bootstrap=True,
                                      criterion='gini',
                                      random_state=RANDOM_STATE,
                                      n_jobs=4,
                                      verbose=0)
    # results = cross_validate(model_rf,
    #                          X_train,
    #                          Y_train,
    #                          cv=10,
    #                          scoring=['balanced_accuracy'],
    #                          return_train_score=True,
    #                          return_estimator=True)
    model_rf.fit(x_train, y_train)
    return model_rf, (x_test, y_test)


def train_on_encrypted_data(data_alice, data_bob):
    """Encapsulates the functionalities to train a classifier on
    independently encrypted data

    :param data_alice: tuple with 2 DataFrames for train & test from Alice
    :param data_bob: tuple with 2 DataFrames for train & test from Bob
    :return: tuple (classifier model, tuple (features test, target test))
    """
    if PARALLELIZE:
        encoded_test_data = parallelize_encoding(data_alice, data_bob)
    else:
        encoded_test_data = []
        for subset_train_test_tuple in [data_alice, data_bob]:
            encoded_test = wrap_encode(subset_train_test_tuple)
            encoded_test_data.append(encoded_test)
        encoded_test_data = pd.concat(encoded_test_data)

    x = encoded_test_data.drop('y', axis=1)
    y = encoded_test_data['y']

    return fit_rf_classifier(x, y)


def verif_valid(model, x, y):
    """Extract performance metrics to evaluate the classifier model

    :param model: classifier model
    :param x: DataFrame with features
    :param y: Series with target
    :return: None
    """
    pred = model.predict(x)
    print('Confusion matrix :')
    print(confusion_matrix(y, pred))
    print('Associated quality metrics :')
    print(classification_report(y, pred))
    print('AUC score :')
    print(roc_auc_score(y, pred))


def train_on_raw_data(data_alice, data_bob):
    """Encapsulates the functionalities to train a classifier on raw data

    :param data_alice: tuple with 2 DataFrames for train & test from Alice
    :param data_bob: tuple with 2 DataFrames for train & test from Bob
    :return: tuple (classifier model, tuple (features test, target test))
    """
    raw_test_data = pd.concat([data_alice[1], data_bob[1]])
    x = raw_test_data.drop('Class', axis=1)
    y = raw_test_data['Class']

    return fit_rf_classifier(x, y)


def main():
    """Main

    :return: None
    """
    data = pd.read_csv(PATH + 'creditcard.csv')

    data_train, data_test = train_test_split_custom(data)

    data_alice, data_bob = zip(np.array_split(data_train, 2),
                               np.array_split(data_test, 2))

    # Use an autoencoder to transform the raw data before fitting the model
    classifier, (x_test, y_test) = \
        train_on_encrypted_data(data_alice, data_bob)
    print('Results with independently encoded data :\n')
    verif_valid(classifier, x_test, y_test)

    # Use an autoencoder to transform the raw data before fitting the model
    classifier, (x_test, y_test) = train_on_raw_data(data_alice, data_bob)
    print('\nResults with raw data :\n')
    verif_valid(classifier, x_test, y_test)


if __name__ == '__main__':
    main()
