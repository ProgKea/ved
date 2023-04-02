cursor = 6
words = ["Hello", ",", "world", "!"]

for i in range(len(words)):
    if cursor < sum(map(len, words[:i])):
        print(words[i-1])
        break
