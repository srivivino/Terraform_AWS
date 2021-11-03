from functools import reduce
import operator

def defaultInput(object, defaultKeys):

    keyList=defaultKeys.split("/")
    return reduce(operator.getitem, keyList, object)

def userInput(object, userkey, valid_inputs):
    
    keyList = userkey.split('/')

    # Validating user input key for the Value  
    if userkey not in valid_inputs:
        print('You have entered the Invalid Input, Kindly refer the valid inputs and Enter the key from the below suggestions \n {}'.format(valid_inputs))
        return "None"
    
    if len(keyList) == 1 and userkey == 'x':
        res = object.get(userkey, {})
        return res
    
    elif len(keyList) == 1 and userkey == 'y':
        res = object.get('x', {}).get(keyList[0], {})
        return res
    
    elif len(keyList) == 1 and userkey == 'z':
        res = object.get('x', {}).get('y', {}).get(keyList[0], {})
        return res
    
    elif len(keyList) == 2 and userkey == 'x/y':
        res = object.get(keyList[0], {}).get(keyList[1], {})
        return res
    
    if len(keyList) == 2 and userkey == 'y/z':
        res = object.get('x', {}).get(keyList[0], {}).get(keyList[1], {})
        return res
    
    elif len(keyList) == 3 and userkey == 'x/y/z':
        res = object.get(keyList[0], {}).get(keyList[1], {}).get(keyList[2], {})
        return res

def Object_1():
    choice=input('Enter "Yes / Y" If you want the value for Default Input "x/y/z", else Enter "No / N" If you want the value of your custom input key ("Y/N"):  ')
    object = {"x":{"y":{"z":"a"}}}
    valid_inputs = ['x', 'y', 'z', 'x/y', 'y/z', 'x/y/z']
    result = "None"
    if (choice.lower() == "yes" or choice.lower() == 'y'):
        result = defaultInput(object, "x/y/z")
        print('\n Your Value for the given Key is: {}'.format(result))
    elif (choice.lower() == "no" or choice.lower() == 'n'):
        userInputKey = input("Valid Inputs are {} \n Enter your Key for the Value: ".format(valid_inputs))
        result = userInput(object, userInputKey, valid_inputs)
        print('\n Your Value for the given Key is: {}'.format(result))
    else:
        print('You have entered the wrong choice, kindly Enter "Yes/No"')

Object_1()