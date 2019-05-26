# REACT-NATIVE MEMO

## I. Set up

General commands :
- `$ sudo npm install -g expo-cli`
- `$ cd ~/Documents/POCs/react_native/`

Create app :
- `$ expo init MoviesAndMe`
- `$ npm start`

`App.js` file content :
```
// App.js
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

export default class App extends React.Component {
    render() {
        return (
        <View style={styles.container}>
            <Text>Hello !</Text>
        </View>
        );
    }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#fff',
        alignItems: 'center',
        justifyContent: 'center',
    },
});
```


## II. Create first components

Code using `JSX` ! (Inspired from HTML & XML)
It looks like :
```
<View>
    <TextInput placeholder="Titre du film"/>
    <Button title="Rechercher" onPress={() => {}}/>
</View>
```
Which will be converted in React, to give :
```
React.createElement(View, {},
  	React.createElement(TextInput, {placeholder: "Titre du film"}),
    React.createElement(Button, {title: "Rechercher", onPress: () => {}})
)
```

We'll create a `Search` component !
- Create a folder `Components` in the root of the app
- Create the file `Search.js` in that folder, such as :
```
// Components/Search.js
import React from 'react'
import { View, TextInput, Button } from 'react-native'

class Search extends React.Component {
    render() {
        return (
            <View>
                <TextInput placeholder='Titre du film'/>
                <Button title='Rechercher' onPress={() => {}}/>
            </View>
        )
    }
}

export default Search
```
And change the `App.js`, such as :
```
// App.js
import React from 'react';
import Search from './Components/Search'

export default class App extends React.Component {
    render() {
        return (
            <Search/>
        );
    }
}
```


## III. Apply a style

For example, we want to add a margin to the top.

Here's what we'll write in `Components/Search.js` :

```
render() {
    return (
        <View style={{ marginTop: 20 }}>
            <TextInput placeholder='Titre du film'/>
            <Button title='Rechercher' onPress={() => {}}/>
        </View>
    )
 }
```

It is quite similar to CSS !

Some documentations about different styles for different components ...

Cf. Cheach sheet : [react-native-styling-cheat-sheet](https://github.com/vhpoet/react-native-styling-cheat-sheet#flexbox)

NB : We can't apply a style on custom components !

It's more convenient to externalise the styles if we need to use them at several places.

For example, in `Search.js` :

```
// Search.js

// ...

const styles = {
  textinput: {
    marginLeft: 5,
    marginRight: 5,
    height: 50,
    borderColor: '#000000',
    borderWidth: 1,
    paddingLeft: 5
  }
}

export default Search
```

And

```
<TextInput style={styles.textinput} placeholder='Titre du film'/>
```

If we extrernalize the styles, we'll be able to use `StyleSheet` : an API that improves styles performance using an index.

To do so, still in `Search.js` :

```
import { StyleSheet, View, TextInput, Button } from 'react-native'
```
And
```
const styles = StyleSheet.create({
  textinput: {
    marginLeft: 5,
    marginRight: 5,
    height: 50,
    borderColor: '#000000',
    borderWidth: 1,
    paddingLeft: 5
  }
})
```


## IV. Flexbox

In React Native, all the components use Flexbox, and can be seen as `flexible boxes` !

Rather than defining static sizes, we'll split our view in several blocs, and mention the share they'll be allowed to take ! To do so, we'll use the `flex` style.

Let's have a look :
```
render() {
    return (
      <View style={{ flex: 1, backgroundColor: 'yellow' }}>
        <View style={{ flex: 1, backgroundColor: 'red' }}></View>
        <View style={{ flex: 1, backgroundColor: 'green' }}></View>
      </View>
    )
}
```
Here, we'll split equally the red part (top of the screen) and the green one (bottom). They'll have 1 piece each, and since those pieces are equal, they'll share the whole screen equally !

The yellow view is there to set up the flex style (it equals 0 by default), so we want it to take all the available space ! If we didn't set the yellow view, the child (views red & green) would wait the aprent's size to define their own, but without set up, the yellow view will be awaiting the childrens to define which size to provide them ...

Whithout the flex style at  on the yellow view, the app won't be able tyo show up anything !

Some examples of workaround using flex :

```
render() {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: 'yellow' }}>
        <View style={{ height: 50, width: 50, backgroundColor: 'red' }}></View>
        <View style={{ height: 50, width: 50, backgroundColor: 'green' }}></View>
        <View style={{ height: 50, width: 50, backgroundColor: 'blue' }}></View>
      </View>
    )
}
```

Will display 3 views (red, green, blue) with a static size, in the center (`justifyContent` stands to aligh in the column, and `alignItems` in the row) of a big yellow view as a background !

Rather than `center`, we could use the following values :
- `justifyContent` :
   - `center` -> center
   - `flex-start` -> top
   - `flex-end` -> bottom
   - `space-between` -> all along the height
   - others : `space-around`, `space-evenly`, ...
- `alignItems` :
   - `center` -> center
   - `flex-start` -> left
   - `flex-end` -> right
   - `stretch` -> all along the width


## V. Use Props





