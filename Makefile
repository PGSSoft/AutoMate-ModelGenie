.PHONY: docs push_github

# Push master, develop and tags to GitHub
push_github:
	git push github develop
	git push github master
	git push github --tags
