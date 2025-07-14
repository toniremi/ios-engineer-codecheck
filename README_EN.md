# Yumemi Inc. iOS Engineer Code Check Challenge

## Overview

This project is a base project for the challenge given by Yumemi Inc. (hereinafter referred to as "the Company") to those who wish to become iOS engineers at our company. If you have been assigned this challenge, please read the following explanation carefully before proceeding.

For new graduates/inexperienced engineers, instead of the regular refactoring challenge, you can also choose the [special challenge of creating a new app](https://yumemi-ios-junior-engineer-codecheck.app.swift.cloud). Please choose the one you feel more confident with. If you choose the special challenge, you do not need to work on the regular challenge. Please read the explanation for the new app creation challenge carefully before proceeding.

## App Specifications

This app is a GitHub repository search app.

![Operation Image](README_Images/app.gif)

### Environment

- IDE: Generally the latest stable version (Xcode 15.2 at the time of this overview update)
- Swift: Generally the latest stable version (Swift 5.9 at the time of this overview update)
- Development Target: Generally the latest stable version (iOS 17.2 at the time of this overview update)
- Use of third-party libraries: Not restricted as long as they are open source

### Operation

1. Enter any keyword.
2. Search for repositories using the GitHub API (`search/repositories`) and display a list of results with an overview (repository name).
3. If a specific result is selected, display the details of the corresponding repository (repository name, owner icon, project language, Star count, Watcher count, Fork count, Issue count).

## How to approach the challenge

After checking the Issues, please [**Duplicate** this project](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/duplicating-a-repository) (do not Fork it; you can make it a private repository if necessary). All future commits should be made in your own repository.

All code check challenge Issues are tagged with the [`課題`](https://github.com/yumemi/ios-engineer-codecheck/milestone/1) Milestone and are divided into [`Beginner (初級)`](https://github.com/yumemi/ios-engineer-codecheck/issues?q=is%3Aopen+is%3Aissue+label%3A初級+milestone%3A課題), [`Intermediate (中級)`](https://github.com/yumemi/ios-engineer-codecheck/issues?q=is%3Aopen+is%3Aissue+label%3A中級+milestone%3A課題+) and [`Bonus (ボーナス)`](https://github.com/yumemi/ios-engineer-codecheck/issues?q=is%3Aopen+is%3Aissue+label%3Aボーナス+milestone%3A課題+) labels according to their difficulty:

|   | Beginner (初級) | Intermediate (中級) | Bonus (ボーナス)
|--:|:--:|:--:|:--:|
| New Grad / Inexperienced | Required | Optional | Optional |
| Mid-career / Experienced | Required | Required | Optional |

We have prepared GitHub Actions to copy the challenge Issues to your repository. You can copy them by [manually triggering this Workflow](./.github/workflows/copy-issues.yml). Please make use of it.

Once the challenge is complete, please inform us of your repository address.

## Reference Information

Please refer to the following for detailed evaluation points for submitted challenges.

- [What I look for when code checking (iOS engineers) for hiring](https://qiita.com/lovee/items/d76c68341ec3e7beb611)
- [CocoaPods Usage Guide](https://qiita.com/ykws/items/b951a2e24ca85013e722)
- [Trying code refactoring with ChatGPT (Model: GPT-4)](https://qiita.com/mitsuharu_e/items/213491c668ab75924cfd)

The use of AI services such as ChatGPT is not prohibited. You may receive additional credit for submitting creative prompts or source comments when using them (there will be no negative evaluation).